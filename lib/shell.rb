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

    def run_interactively
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

    def prompt
      "\e[0;36m[\e[1;32m#{Process.pid}\e[0;36m]\033[0m% "
    end

    def define_sigchld_handler
      Signal.trap :CHLD do
        @job_table.jobs.each do |id, job|
          job.reap_children Process::WNOHANG
        end
      end
    end
  end
end
