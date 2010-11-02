# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/command"
require "strscan"

module Urchin
  # TODO: handle the following:
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
  #   Exit code logic:
  #
  #   * cd /dir && ls -l
  #   * cd ~ms || cd ~mark
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
      jobs
    end

    def parse_job
      until end_of_job?
        job ||= Job.new([], @shell)
        if command = parse_command
          until end_of_command?
            parse_redirects(command)
          end
          job << command
        end
      end
      finalise_job(job) unless job.nil?
    end

    def finalise_job(job)
      if background?
        job.start_in_background!
      else
        @input.scan(/;/)
      end
      job
    end

    def background?
      @input.scan(/^&/)
    end

    def end_of_command?
      remove_space
      @input.eos? || @input.scan(/\|/) || end_of_job?
    end

    def parse_redirects(command)
      if @input.scan(/^>>/)
        if target = word
          command.add_redirect(STDOUT, target, "a")
        end
      elsif @input.scan(/^>/)
        if target = word
          command.add_redirect(STDOUT, target, "w")
        end
      elsif @input.scan(/^</)
        if target = word
          command.add_redirect(STDIN, target, "r")
        end
      end
    end

    # Returns if this is the end of the job. Does not advance the string pointer.
    def end_of_job?
      @input.eos? || @input.check(/^[;&]/)
    end

    def remove_space
      @input.scan(/\s+/)
    end

    # Returns the Command object associated with the next words in the input
    # string. Otherwise, nil.
    def parse_command
      if ws = words
        command = Command.new(ws.shift)
        ws.each { |word| command << word }
        return command
      end
      false
    end

    # Returns a single word if it is next in the input string. Otherwise, nil.
    def word
      remove_space
      while part = (word_part or escaped_char)
        output ||= ""
        output << part
      end
      output
    end

    def quoted_word
      if char = @input.scan(/^["']/)
        while part = (quoted_word_part(char) or escaped_char(char))
          output ||= ""
          output << part
          break if end_of(char)
        end
      end
      output
    end

    def end_of(char)
      @input.scan(/^#{char}/)
    end

    def quoted_word_part(char)
      @input.scan(/[^\\#{char}]+/)
    end

    def word_part
      @input.scan(/[^&|;><\s\\]+/)
    end

    # Returns unescaped character that is passed, if it is next and escaped.
    def escaped_char(char = '.')
      if escaped = @input.scan(/^\\#{char}/)
        return escaped[1,1]
      end
      false
    end

    # Returns an array of the next words or nil.
    def words
      remove_space
      while w = (quoted_word or word)
        words ||= []
        words << w
        remove_space
      end
      return words
    end
  end
end
