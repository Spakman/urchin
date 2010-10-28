# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/command"
require "strscan"

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
      @input = StringScanner.new(input)
      jobs = []
      while job = parse_job
        jobs << job
      end
      return jobs
    end

    def trim_space
      @input.scan(/\s+/)
    end

    def parse_job
      @current_job = Job.new([], @shell)
      while !ampersand && !semi && pipe && command = parse_command
        @current_job << command
      end
      @current_job unless @current_job.empty?
    end

    def pipe
      @input.scan(/\|?/)
    end

    def ampersand
      @input.scan(/&/)
    end

    def semi
      @input.scan(/;/)
    end

    def parse_command
      trim_space
      if word = parse_word
        command = Command.new(word)
        while !parse_end_command && arg = parse_word
          command << arg
        end
        return command
      end
      false
    end

    def parse_end_command
      trim_space
      @input.scan(/[&|;]/)
      case @input.matched
      when "&"
        @current_job.start_in_background!
        @input.pos = @input.pointer - 1 unless @input.eos?
        true
      when "|", ";"
        @input.pos = @input.pointer - 1 unless @input.eos?
        true
      end
    end

    def parse_string_content
      @input.scan(/[^\\"]+/) and @input.matched
    end

    def parse_string_escape
      if @input.scan(%r{\\["\\/]})
        @input.matched[-1]
      else
        false
      end
    end

    def parse_word
      trim_space
      if @input.scan(/"/)
        word = ""
        while contents = parse_string_content || parse_string_escape
          word << contents
        end
        @input.scan(/"/)
        word
      elsif @input.scan /[^\s|;|&]+/
        @input.matched.strip
      else
        false
      end
    end
  end
end
