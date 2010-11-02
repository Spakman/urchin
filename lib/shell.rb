# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "readline"
require "#{File.dirname(__FILE__)}/parser"
require "#{File.dirname(__FILE__)}/job"
require "#{File.dirname(__FILE__)}/urchin_runtime_error"

module Urchin
  class Shell
    attr_reader :job_table, :terminal_modes

    def initialize
      @job_table = JobTable.new
      @parser = Parser.new(self)
      define_sigchld_handler
      @terminal_modes = Termios.tcgetattr(STDIN)
      @interactive = false
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
      begin
        while input = Readline.readline(prompt)
          next if input.empty?
          Readline::HISTORY.push(input)
          run input
        end
      rescue Interrupt
        puts "^C"
        retry
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

      # Ensure we are in our own process group.
      Process.setpgid(Process.pid, Process.pid)
      Termios.tcsetpgrp(STDIN, Process.getpgrp)

      @interactive = true
    end

    def prompt
      "\e[0;36m[\e[1;32m#{Process.pid}\e[0;36m]\033[0m% "
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
