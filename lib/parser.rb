# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/command"

module Urchin
  # Really dumb command parser for now.
  class Parser
    def self.jobs_from(input)
      input.split(";").map do |job_string|
        background = false
        commands = []

        command_strings = job_string.split("|")

        if command_strings.last.strip[-1,1] == "&"
          background = true
          command_strings.last.gsub!("&", "")
        end

        command_strings.each do |command_string|
          args = command_string.split(" ").map { |a| a.strip }
          command = Command.create(args.shift)
          command.append_arguments args
          commands << command
        end

        job = Job.new(commands)
        job.start_in_background! if background
        job
      end
    end
  end
end
