# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module RSH
  # Really dumb command parser for now.
  class Parser
    def self.jobs_from(input)
      input.split(";").map do |commands|
        Job.new(commands)
      end
    end
  end
end
