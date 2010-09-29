# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "readline"
require "#{File.dirname(__FILE__)}/parser"
require "#{File.dirname(__FILE__)}/job"

module Urchin
  class Shell
    def run(command_string)
      Parser.jobs_from(command_string).each do |job|
        begin
          job.run
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
  end
end
