# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "readline"
require "#{File.dirname(__FILE__)}/command_parser"
require "#{File.dirname(__FILE__)}/job"

module RSH
  class Shell
    def run
      while line = Readline.readline(prompt)
        next if line.empty?
        Readline::HISTORY.push(line)

        CommandParser.jobs_from(line).each do |job|
          job.run
          job.pids.each do |pid|
            Process.wait pid
          end
        end
      end
    end

    def prompt
      "\e[0;36m[\e[1;32m#{Process.pid}\e[0;36m]\033[0m% "
    end
  end
end
