# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/command"

module Urchin
  # Really dumb command parser for now.
  class Parser
    def self.jobs_from(input)
      input.split(";").map do |job|
        commands = []

        job.split("|").each do |command_string|
          args = command_string.split(" ").map { |a| a.strip }
          command = Command.create(args.shift)
          command.append_arguments args
          commands << command
        end

        Job.new(commands)
      end
    end
  end
end
