# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  # TODO: handle the following:
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
  class Parser
    def initialize(shell)
      @shell = shell
    end

    def jobs_from(input)
      @input = StringScanner.new(input)
      jobs = []
      until @input.eos?
        if job = parse_job
          jobs << job
        end
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
      finalise_job(job)
    end

    def finalise_job(job)
      if background? && job
        job.start_in_background!
      else
        @input.scan(/^;/)
      end
      job
    end

    def background?
      @input.scan(/^&/)
    end

    def end_of_command?
      remove_space
      @input.eos? || @input.scan(/^\|/) || end_of_job?
    end

    # TODO: clean this up.
    # TODO: handle arbitrary FDs.
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
      elsif @input.scan(/^2>&/)
        if word == "1"
          command.add_redirect(STDERR, STDOUT, "w")
        end
      elsif @input.scan(/^2>>/)
        if target = word
          command.add_redirect(STDERR, target, "a")
        end
      elsif @input.scan(/^2>/)
        if target = word
          command.add_redirect(STDERR, target, "w")
        end
      end
    end

    # Returns if this is the end of the job. Does not advance the string pointer.
    def end_of_job?
      @input.eos? || @input.check(/^[;&]/)
    end

    def remove_space
      @input.scan(/^\s+/)
    end

    # Returns the Command object associated with the next words in the input
    # string. Otherwise, nil.
    def parse_command
      if executable = word
        command = Command.create(executable, @shell.job_table)
        words.each do |arg|
          command << arg
        end
        return command
      else
        false
      end
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

    # Returns if the word is a glob pattern.
    def is_a_glob?(word)
      word =~ /(:? [*?] | \[.+\] | \{.+ (:? ,.+)+\} )/x
    end

    # Returns a list of words matching the glob pattern specified in word, if
    # it is a glob pattern. Otherwise, just return an array containing word.
    def words_from_glob(word)
      if is_a_glob? word
        Dir.glob(word) - [ ".", ".." ]
      else
        [ word ]
      end
    end

    # Returns a quoted word that is free from quotes and escaped quote
    # characters.
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
      # Check to see if the next word part is a redirect.
      if @input.check(/^\d+>/)
        false
      else
        @input.scan(/^[^&|;><\s\\]+/)
      end
    end

    # Returns unescaped character that is passed, if it is next and escaped.
    def escaped_char(char = '.')
      if escaped = @input.scan(/^\\#{char}/)
        return escaped[1,1]
      end
      false
    end

    def words
      words = []
      begin
        remove_space
        w = nil
        if w = quoted_word
          words << w
        elsif w = word
          words += perform_expansions(w)
        end
      end until w.nil?
      words
    end

    def tilde_expansion(word)
      @slash_home ||= ENV['HOME'].sub(%r{/\w+?$}, "/")
      if word =~ %r{^~\w+/?}
        word.sub!("~", @slash_home)
      end
      if word =~ %r{^~/?}
        word.sub!("~", ENV['HOME'])
      end
      word
    end

    def perform_expansions(word)
      word = tilde_expansion(word)
      words_from_glob(word)
    end
  end
end
