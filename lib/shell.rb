# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "readline"
require "#{File.dirname(__FILE__)}/command_parser"
require "#{File.dirname(__FILE__)}/job"

module RSH
  class Shell
    def run
      while line = Readline.readline('> ')
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
  end
end
