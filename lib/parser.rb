# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/command"

module Urchin
  # Really dumb command parser for now.
  #
  # TODO: implement a proper parser.
  #
  #   Here are some cases that it should be able to handle:
  #
  #   Pipelines:
  #
  #   * ls -la | head | tail
  #
  #   Seperate jobs:
  #
  #   * uptime ; sleep 1 ; top
  #   * sleep 60 & echo 123
  #
  #   Quoting and escaping:
  #
  #   * grep -r "this is a quoted string" .
  #   * grep -r 'this is a quoted string' .
  #   * grep -r this\ is\ an\ escaped\ string .
  #
  #   Redirects:
  #
  #   * ls > output
  #   * ls >> output
  #   * patch -p0 < code.patch
  #   * ls 2>&1
  #   * patch -p0 2>&1 > output < code.patch
  #
  #   Command/tilde/alias expansion:
  #
  #   * ls -lh `cat thepath` | head -2
  #   * ls ~/.config
  #
  #   Environment variables:
  #
  #   * VAR=hello echo $VAR; echo $VAR
  #
  #   Inline Ruby code:
  #
  #   * ls | ~@ p STDIN.gsub(/^*\..*/, "") @~ | tail
  #
  #   Simple calculations:
  #
  #   * (12 * 56) - 33
  #
  #   Globbing/brace expansion:
  #
  #   * ls {img,image}.{png,jpg}
  #   * ls *.{png,jpg}
  #   * ls **/*.{png,jpg}
  #   * ls 00[123].{png,jpg}
  class Parser
    def initialize(shell)
      @shell = shell
    end

    def jobs_from(input)
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
          command = Command.create(args.shift, @shell.job_table)
          args.map { |arg| command << arg } 
          commands << command
        end

        job = Job.new(commands, @shell)
        job.start_in_background! if background
        job
      end
    end
  end
end
