# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class Shell
    attr_reader :job_table, :terminal_modes, :history
    @@aliases = {}

    def initialize
      @job_table = JobTable.new
      @parser = Parser.new(self)
      define_sigchld_handler
      @terminal_modes = Termios.tcgetattr(STDIN) if STDIN.tty?
      @interactive = false
    end

    def setup_history
      if File.readable? URCHIN_HISTORY
        File.readlines(URCHIN_HISTORY).each do |line|
          Readline::HISTORY.push line.chomp
        end
      end
      @history = File.open(URCHIN_HISTORY, "a+")
      begin
        @history.close_on_exec = true
      rescue NoMethodError
      end
    end

    def self.alias(hash)
      @@aliases.merge! hash
    end

    def aliases
      @@aliases
    end

    def is_interactive?
      @interactive
    end

    def run(command_string)
      @parser.jobs_from(command_string).each do |job|
        begin
          begin
            job.run
          rescue UrchinRuntimeError => error
            STDERR.puts error.message
          end
        rescue Interrupt
          puts ""
        end
      end
    end

    # Starts the command line processing loop.
    #
    # TODO: nicer history management.
    def run_interactively
      setup_interactivity
      setup_history
      begin
        while input = Readline.readline(prompt)
          add_to_history input
          run input
        end
      rescue Interrupt
        puts "\n^C"
        retry
      end
      @history.close
    end

    # Appends the input to the Readline history (if it was not a duplicate of
    # the previous line) and writes it to the history file.
    #
    # TODO: use /dev/shm or some other method to save constant flushing.
    #
    # TODO: limit the number of entries in the history file.
    def add_to_history(input)
      unless input.empty? || Readline::HISTORY.to_a.last == input
        Readline::HISTORY.push(input)
        @history << "#{input}\n"
        @history.flush
      end
    end

    # Ensures the Shell is in the foreground and ignores job-control signals so
    # it can perform job control itself.
    def setup_interactivity
      unless STDIN.tty?
        STDERR.puts "STDIN is not a TTY."
        exit 1
      end
      unless STDERR.tty?
        STDERR.puts "STDERR is not a TTY."
        exit 1
      end

      # Ensure we are the foreground job before starting to run interactively.
      while Termios.tcgetpgrp(STDIN) != Process.getpgrp
        Process.kill("-TTIN", Process.getpgrp)
      end

      # Ignore interactive and job-control signals.
      Signal.trap :QUIT, "IGNORE"
      Signal.trap :TSTP, "IGNORE"
      Signal.trap :TTIN, "IGNORE"
      Signal.trap :TTOU, "IGNORE"

      Termios.tcsetpgrp(STDIN, Process.getpgrp)

      @interactive = true
    end

    # Defines the prompt method.
    def self.prompt(&block)
      define_method :prompt do
        block.call
      end
    end

    if RUBY_PLATFORM =~ /linux/
      # TODO: consider Bash-like escaping (\[\]).
      def prompt
        "\001\e[0;36m\002(\001\e[1;32m\002#{Dir.getwd}\001\e[0;36m\002)\001\033[0m\002% "
      end
    elsif RUBY_PLATFORM =~ /darwin/
      # OS X doesn't seem to like (or need) the \001\002 escaping, at least on
      # the box I have SSH access to.

      def prompt
        "\e[0;36m(\e[1;32m#{Dir.getwd}\e[0;36m)\033[0m% "
      end
    else
      # Other platforms are untested.

      def prompt
        "(#{Dir.getwd}) % "
      end
    end

    # Foreground child processes can also be caught by the
    # Job itself, but we need to add this here to ensure
    # there are no zombies.
    def define_sigchld_handler
      Signal.trap :CHLD do
        @job_table.jobs.each do |job|
          job.reap_children Process::WNOHANG
        end
      end
    end
  end
end
