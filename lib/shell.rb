# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class Shell
    attr_reader :job_table, :terminal_modes, :history

    @ruby_delimiter = "~@"
    class << self
      attr_accessor :ruby_delimiter
    end

    @@aliases = {}

    def initialize
      @job_table = JobTable.new
      @parser = Parser.new(self)
      define_sigchld_handler
      @terminal_modes = Termios.tcgetattr(STDIN) if STDIN.tty?
      @history = History.new
    end

    # Starts the command line processing loop.
    def run
      setup_terminal_and_signals
      begin
        while input = Readline.readline(prompt)
          @history.append input
          parse_and_run input

          # If the terminal was resized while we were running a job in the
          # foreground, Urchin will not have received SIGWINCH and will have
          # incorrect LINES and COLUMNS envrironment variables set, so let's
          # check the terminal size.
          RbReadline._rl_get_screen_size(STDIN.fileno, 1)
        end
      rescue Interrupt
        puts "\n^C"
        retry
      end
    end

    # Parse the command string and run any jobs within it in turn.
    def parse_and_run(command_string)
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

    # Ensures the Shell is in the foreground and ignores job-control signals so
    # it can perform job control itself.
    def setup_terminal_and_signals
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

    # Adds hash to the list of aliases.
    #
    # These are set in URCHIN_RB, like so:
    #
    # Shell.alias "ls" => "ls --color"
    def self.alias(hash)
      @@aliases.merge! hash
    end

    # Returns the hash of aliases.
    def aliases
      @@aliases
    end

    # Defines the prompt method.
    def self.prompt(&block)
      undef :prompt
      define_method :prompt do
        block.call
      end
    end

    if RUBY_PLATFORM =~ /linux/
      # Returns the prompt for terminal display.
      #
      # TODO: consider Bash-like escaping (\[\]).
      def prompt
        "\001\e[0;36m\002(\001\e[1;32m\002#{Dir.getwd}\001\e[0;36m\002)\001\033[0m\002% "
      end
    elsif RUBY_PLATFORM =~ /darwin/
      # OS X doesn't seem to like (or need) the \001\002 escaping, at least on
      # the box I have SSH access to.

      # Returns the prompt for terminal display.
      def prompt
        "\e[0;36m(\e[1;32m#{Dir.getwd}\e[0;36m)\033[0m% "
      end
    else
      # Other platforms are untested.

      # Returns the prompt for terminal display.
      def prompt
        "(#{Dir.getwd}) % "
      end
    end
  end
end
