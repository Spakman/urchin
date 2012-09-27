# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  # TODO: handle the following:
  #
  #   Exit code logic:
  #
  #   * cd /dir && ls -l
  #   * cd ~ms || cd ~mark
  class Parser
    def initialize(shell, input = nil)
      @shell = shell
      @input = StringScanner.new(input) if input
      @expecting_new_command = false
      @finished_entering_alias = true
    end

    def jobs_from(input)
      @input = StringScanner.new(input)
      jobs = []
      if source = parse_line_of_ruby
        ruby = RubyProcess.create("puts eval(ARGV.last)") << source
        jobs << (Job.new([], @shell) << ruby)
      else
        until @input.eos?
          if job = parse_job
            jobs << job
          end
        end
      end
      jobs
    end

    def parse_line_of_ruby
      remove_space
      if source = @input.scan(/^[0-9].*$/)
        source
      end
    end

    def start_of_new_command?
      @expecting_new_command
    end

    def parse_job
      until end_of_job?
        job ||= Job.new([], @shell)
        command_variables = {}
        while var = environment_variable
          command_variables.merge! var
        end
        if ruby = parse_ruby
          ruby.environment_variables = command_variables
          job << ruby
          until end_of_command?
            parse_redirects(ruby)
          end
        elsif command = parse_command
          command.environment_variables = command_variables
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
      if @input.scan(/^\|/)
        @expecting_new_command = true
      else
        return false unless @input.eos? || end_of_job?
      end
      true
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
      command_expansion
      if alias_end_pos = alias_expansion
        @finished_entering_alias = false
      end
      if executable = tilde_expansion(word)
        command = Command.create(variable_expansion(executable), @shell.job_table)
        words.each do |arg|
          command << arg
        end
        if @input.pos > alias_end_pos
          @finished_entering_alias = true
        end
        return command
      else
        false
      end
    end

    def finished_entering_alias?
      @finished_entering_alias
    end

    # Returns a RubyCommand object to run the Ruby code between the next two
    # Ruby delimiters or false.
    def parse_ruby
      remove_space
      if @input.scan(/^#{Regexp.escape(Shell.ruby_delimiter)}/)
        extra_args = @input.scan(/^[^\s]+/)
        source = @input.scan(/(.+?)#{Regexp.escape(Shell.ruby_delimiter)}/)
        source.gsub! Shell.ruby_delimiter, ""
        ruby = RubyProcess.create(source)
        ruby << extra_args if extra_args
        ruby
      else
        false
      end
    end

    # Returns a single word if it is next in the input string. Otherwise, nil.
    def word(options = { :trim => true })
      remove_space unless options[:trim] == false
      while part = (word_part or escaped_char)
        output ||= ""
        output << part
      end
      output
    end

    # Returns an argument with an equals in it if it is next in the input
    # string. For example:
    #
    #   --my-arg="here's a value"
    #
    # Otherwise, nil.
    def arg_with_equals(options = { :trim => true })
      pos = @input.pos
      remove_space unless options[:trim] == false
      arg = word
      if equals = @input.scan(/^=/)
        arg << equals
        arg << (quoted_word(:strip => false) or word(:trim => false))
      else
        @input.pos = pos
        nil
      end
    end

    def environment_variable
      remove_space
      if variable = @input.scan(/^[A-Z0-9a-z_]+=/)
        value = (quoted_word or word(:trim => false))
        { variable.chop => value }
      end
    end

    # Returns if the word is a glob pattern.
    def is_a_glob?(word)
      word =~ /(:? [*?] | \[.+\] | \{.+ (:? ,.+)+\} )/x
    end

    # Returns a list of words matching the glob pattern specified in word, if
    # it is a glob pattern. Otherwise, just return an array containing word.
    def words_from_glob(word)
      if is_a_glob? word
        files = Dir.glob(word) - [ ".", ".." ]
        if files.any?
          return files.sort
        end
      end
      [ word ]
    end

    # Returns a quoted word that is free from quotes and escaped quote
    # characters.
    def quoted_word(options =  { :strip => true })
      if char = @input.scan(/^["']/)
        output = ""
        unless options[:strip]
          output << char
        end
        while part = (quoted_word_part(char) or escaped_char(char))
          output << part
          break if end_of(char)
        end
        unless options[:strip]
          output << char
        end
        end_of(char) if output.empty?
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
        @input.scan(/^[^&=|;><\s\\]+/)
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
        command_expansion
        remove_space
        w = nil
        if w = quoted_word
          words << w
        elsif w = (arg_with_equals or word)
          words += perform_expansions(w)
        end
      end until w.nil?
      words
    end

    # Performs tilde expansion on a word.
    #
    # For example:
    #
    # ls ~
    # ls ~/src
    # ls ~spakman/src/
    def tilde_expansion(word)
      home = ENV['HOME'].sub(%r{/\w+?$}, "/")
      if word =~ %r{^~\w+/?}
        word.sub!("~", home)
      end
      if word =~ %r{^~/?}
        word.sub!("~", ENV['HOME'])
      end
      word
    end

    # Performs environment variable expansions on a word.
    #
    # Variables can be of the form:
    #
    # $VAR   - when a variable is alone:
    #
    #   echo $VAR
    #
    # ${VAR} - to seperate from other characters:
    #
    #   echo hello${VAR}goodbye
    #
    # If the word contains multiple variables, they are expanded in order.
    def variable_expansion(word)
      if word =~ /^\$([A-Za-z0-9_]+)$/
        word = ENV[$1] || ""
      elsif word =~ /\$\{([A-Za-z0-9_]+)\}/
        variable = ENV[$1] || ""
        word.sub!(/\$\{#{$1}\}/, variable)
        word = variable_expansion(word)
      end
      word
    end

    def perform_expansions(word)
      word = variable_expansion(word)
      word = tilde_expansion(word)
      words_from_glob(word)
    end

    # Replaces a command with some text. This is only used for the first
    # (command) word in a command line. The command word is parsed after alias
    # expansion, so the alias can contain multiple commands in a pipeline.
    #
    # Returns the position of the last character of the alias or 0.
    def alias_expansion
      pos = @input.pos
      w = word
      if @shell.aliases[w]
        @input.string = @input.string[pos..-1].sub(w, @shell.aliases[w])
        @input.pos = 0
        @shell.aliases[w].length
      else
        @input.pos = pos
        0
      end
    end

    # Replaces a command string encapsulated in backticks with the result of
    # running it in a sub-shell.
    #
    # Trailing newlines are removed.
    def command_expansion
      remove_space
      pos = @input.pos
      if job_string = @input.scan(/^`.*?`/)
        result = Shell.new.eval(job_string[1...-1]).chomp
        string = @input.string[pos..-1]
        string.sub!(job_string, result)
        @input.string = string
        @input.pos = 0
      end
    end
  end
end
