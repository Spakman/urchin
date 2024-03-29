# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class Shell
    attr_reader :job_table, :terminal_modes, :history, :aliases

    @ruby_delimiter = "~@"
    @completion_highlight_color = Colors::Reset
    @completion_next_character_color = Colors::Reset

    class << self
      attr_accessor :ruby_delimiter
      attr_accessor :completion_highlight_color
      attr_accessor :completion_next_character_color
    end

    def initialize
      @job_table = JobTable.new(self)
      @parser = Parser.new(self)
      define_sigchld_handler
      @terminal_modes = Termios.tcgetattr(STDIN) if STDIN.tty?
      @history = History.new(self)
      @aliases = {}
    end

    # Starts the command line processing loop.
    def run
      perform_pre_run_tasks
      begin
        while input = Readline.readline(prompt)
          start_time = Time.now
          parse_and_run(input)
          write_history_for(input, start_time)

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

    def write_history_for(input, start_time)
      history_line = OpenStruct.new
      history_line.date = start_time
      history_line.input = input
      @history.append history_line
    end

    # Parse the command string and run any jobs within it in turn.
    def parse_and_run(command_string)
      jobs = @parser.jobs_from(command_string)
      if jobs.any?
        time = Time.now
        jobs.each do |job|
          begin
            begin
              @terminal_modes = Termios.tcgetattr(STDIN) if STDIN.tty?
              job.run
              Termios.tcsetattr(STDIN, Termios::TCSADRAIN, @terminal_modes) if STDIN.tty?
            rescue UrchinRuntimeError => error
              STDERR.puts error.message
            end
          rescue Interrupt
            puts ""
          end
        end
        ENV["URCHIN_LAST_TIME"] = "#{(Time.now - time).round(3)}s"
      end
    end

    # Runs the jobs in the command_string and returns the output. It waits for
    # all of the jobs to complete.
    def eval(command_string)
      old_stdin = STDIN.dup
      STDIN.reopen "/dev/null"

      stdout_read, stdout_write = IO.pipe
      stderr_write = stdout_write.dup

      old_stdout = STDOUT.dup
      STDOUT.reopen stdout_write

      old_stderr = STDERR.dup
      STDERR.reopen stderr_write

      parse_and_run command_string

      stdout_write.close
      stderr_write.close
      STDIN.reopen old_stdin
      STDOUT.reopen old_stdout
      STDERR.reopen old_stderr
      output = stdout_read.read and stdout_read.close
      output
    end

    def perform_pre_run_tasks
      setup_terminal_and_signals
      set_urchin_info_env_var
    end

    def set_urchin_info_env_var
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        version = self.eval("git log --pretty=format:%h -1 2>/dev/null").chomp
        if version.empty?
          version = Urchin::VERSION
        else
          diffstat = self.eval("git diff --shortstat 2>/dev/null").chomp
          unless diffstat.empty?
            version = "#{version}-dirty"
          end
        end
        ENV["URCHIN_INFO"] = "#{version} - #{RUBY_DESCRIPTION}"
      end
    end

    # Ensures the Shell is in the foreground and ignores job-control signals so
    # it can perform job control itself.
    def setup_terminal_and_signals
      unless STDIN.tty?
        abort "STDIN is not a TTY."
      end

      if STDIN.tty?
        # Ensure we are the foreground job before starting to run interactively.
        while Termios.tcgetpgrp(STDIN) != Process.getpgrp
          Process.kill("-TTIN", Process.getpgrp)
        end
      end

      # Ignore interactive and job-control signals.
      Signal.trap :QUIT, "IGNORE"
      Signal.trap :TSTP, "IGNORE"
      Signal.trap :TTIN, "IGNORE"
      Signal.trap :TTOU, "IGNORE"

      Termios.tcsetpgrp(STDIN, Process.getpgrp) if STDIN.tty?
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
    # @shell.alias "ls" => "ls --color"
    def alias(hash)
      @aliases.merge! hash
    end

    # Defines the prompt method.
    def self.prompt(&block)
      undef :prompt
      define_method :prompt do
        instance_eval(&block)
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
