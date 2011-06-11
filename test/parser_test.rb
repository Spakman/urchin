require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/parser"
require "#{File.dirname(__FILE__)}/../lib/shell"
require "fileutils"

module Urchin
  class Job; attr_reader :commands, :start_in_background; end

  class Command
    attr_reader :executable, :args, :redirects, :environment_variables

    def ==(object)
      if object.class == Command
        if @executable == object.executable && @args == object.args
          return true
        end
      end
      false
    end
  end

  class Parser
    def setup(input)
      @input = StringScanner.new(input)
    end
  end

  class ParserTestCase < Test::Unit::TestCase
    def setup
      @parser = Parser.new(Shell.new)
      Urchin::Command.send(:public_class_method, :new)
    end

    def test_word
      @parser.setup 'ls'
      assert_equal 'ls', @parser.word
      @parser.setup '  --help'
      assert_equal '--help', @parser.word
      @parser.setup 'ls '
      assert_equal 'ls', @parser.word
      @parser.setup ' -la '
      assert_equal '-la', @parser.word
      @parser.setup '/usr/bin/ls'
      assert_equal '/usr/bin/ls', @parser.word
    end

    def test_words
      @parser.setup 'two words'
      assert_equal %w{ two words }, @parser.words
      @parser.setup '"two words"'
      assert_equal [ 'two words' ], @parser.words
      @parser.setup '"a \"quote\" and stuff"'
      assert_equal [ 'a "quote" and stuff' ], @parser.words
      @parser.setup 'find . -name "hello.*" -exec chmod 660 {} \;'
      assert_equal %w{ find . -name hello.* -exec chmod 660 \{\} ; }, @parser.words
    end

    def test_simple_command
      jobs = @parser.jobs_from('ls')
      assert_equal 1, jobs.size
      assert_equal Command.new('ls'), jobs.first.commands.first

      jobs = @parser.jobs_from('ls -l -a')
      assert_equal 1, jobs.size
      assert_equal Command.new('ls') << '-l' << '-a', jobs.first.commands.first

      jobs = @parser.jobs_from('echo "word" word2')
      assert_equal 1, jobs.size
      assert_equal Command.new('echo') << 'word' << 'word2', jobs.first.commands.first
    end

    def test_pipeline
      jobs = @parser.jobs_from("ls -l |head| wc -l")
      assert_equal 1, jobs.size
      assert_equal 3, jobs.first.commands.size
      assert_equal Command.new("ls") << "-l", jobs.first.commands.first
      assert_equal Command.new("head"), jobs.first.commands[1]
      assert_equal Command.new("wc") << "-l", jobs.first.commands.last
    end

    def test_background_job
      jobs = @parser.jobs_from("sleep 60 &")
      assert_equal 1, jobs.size
      assert_equal Command.new("sleep") << "60", jobs.first.commands.first
      assert jobs.first.start_in_background

      jobs = @parser.jobs_from("sleep 60&")
      assert_equal 1, jobs.size
      assert_equal Command.new("sleep") << "60", jobs.first.commands.first
      assert jobs.first.start_in_background
    end

    def test_multiple_jobs_semi_colon_seperator
      jobs = @parser.jobs_from("uptime; echo 123")
      assert_equal 2, jobs.size
      assert_equal 1, jobs.first.commands.size
      assert_equal Command.new("uptime"), jobs.first.commands.first
      assert_equal 1, jobs.last.commands.size
      assert_equal Command.new("echo") << "123", jobs.last.commands.first

      jobs = @parser.jobs_from("uptime ;echo 123")
      assert_equal 2, jobs.size
      assert_equal 1, jobs.first.commands.size
      assert_equal Command.new("uptime"), jobs.first.commands.first
      assert_equal 1, jobs.last.commands.size
      assert_equal Command.new("echo") << "123", jobs.last.commands.first
    end

    def test_multiple_jobs_with_background_job
      jobs = @parser.jobs_from("uptime & echo 123")
      assert_equal 2, jobs.size
      assert_equal 1, jobs.first.commands.size
      assert_equal Command.new("uptime"), jobs.first.commands.first
      assert_equal 1, jobs.last.commands.size
      assert_equal Command.new("echo") << "123", jobs.last.commands.first
      assert jobs.first.start_in_background
      assert !jobs.last.start_in_background
    end

    def test_redirect_stdout
      jobs = @parser.jobs_from("uptime > output")
      command = jobs.first.commands.first
      assert_equal 1, jobs.size
      assert_equal 1, command.redirects.size
      assert_equal STDOUT, command.redirects.first[:from]
      assert_equal "output", command.redirects.first[:to]
      assert_equal "w", command.redirects.first[:mode]
    end

    def test_redirect_stdout_appending
      jobs = @parser.jobs_from("uptime >> output")
      command = jobs.first.commands.first
      assert_equal 1, jobs.size
      assert_equal 1, command.redirects.size
      assert_equal STDOUT, command.redirects.first[:from]
      assert_equal "output", command.redirects.first[:to]
      assert_equal "a", command.redirects.first[:mode]
    end

    def test_redirect_stdin
      jobs = @parser.jobs_from('ruby -e "puts STDIN.read" < input')
      command = jobs.first.commands.first
      assert_equal 1, jobs.size
      assert_equal 1, command.redirects.size
      assert_equal STDIN, command.redirects.first[:from]
      assert_equal "input", command.redirects.first[:to]
      assert_equal "r", command.redirects.first[:mode]
    end

    def test_redirect_stdin_and_stdout
      jobs = @parser.jobs_from('ruby -e "puts STDIN.read" < input > output')
      command = jobs.first.commands.first
      assert_equal 1, jobs.size
      assert_equal 2, command.redirects.size
      assert_equal STDIN, command.redirects.first[:from]
      assert_equal "input", command.redirects.first[:to]
      assert_equal "r", command.redirects.first[:mode]
      assert_equal STDOUT, command.redirects.last[:from]
      assert_equal "output", command.redirects.last[:to]
      assert_equal "w", command.redirects.last[:mode]
    end

    def test_redirect_sterr_to_stdout
      jobs = @parser.jobs_from('ls /root 2>&1')
      command = jobs.first.commands.first
      assert_equal 1, jobs.size
      assert_equal 1, command.redirects.size
      assert_equal STDERR, command.redirects.first[:from]
      assert_equal STDOUT, command.redirects.first[:to]
      assert_equal "w", command.redirects.first[:mode]
    end

    def test_redirect_sterr_to_file
      jobs = @parser.jobs_from('ls /root 2> error')
      command = jobs.first.commands.first
      assert_equal 1, jobs.size
      assert_equal 1, command.redirects.size
      assert_equal STDERR, command.redirects.first[:from]
      assert_equal "error", command.redirects.first[:to]
      assert_equal "w", command.redirects.first[:mode]
    end

    def test_redirect_sterr_to_file_appending
      jobs = @parser.jobs_from('ls /root 2>> error')
      command = jobs.first.commands.first
      assert_equal 1, jobs.size
      assert_equal 1, command.redirects.size
      assert_equal STDERR, command.redirects.first[:from]
      assert_equal "error", command.redirects.first[:to]
      assert_equal "a", command.redirects.first[:mode]
    end

    def test_redirect_stdin_and_stdout_and_stderr
      jobs = @parser.jobs_from('ruby -e "puts STDIN.read; STDERR.puts 33" < input > output 2>&1')
      command = jobs.first.commands.first
      assert_equal 1, jobs.size
      assert_equal 3, command.redirects.size
      assert_equal STDIN, command.redirects.first[:from]
      assert_equal "input", command.redirects.first[:to]
      assert_equal "r", command.redirects.first[:mode]
      assert_equal STDOUT, command.redirects[1][:from]
      assert_equal "output", command.redirects[1][:to]
      assert_equal "w", command.redirects[1][:mode]
      assert_equal STDERR, command.redirects.last[:from]
      assert_equal STDOUT, command.redirects.last[:to]
      assert_equal "w", command.redirects.last[:mode]
    end

    def test_is_a_glob
      assert @parser.is_a_glob?("*.c")
      assert @parser.is_a_glob?("test/*.rb")
      assert @parser.is_a_glob?("**/hello.rb")
      assert @parser.is_a_glob?("READM?")
      assert @parser.is_a_glob?("image.{png,jpg}")
      assert @parser.is_a_glob?("image.{png,jpg,gif}")
      assert @parser.is_a_glob?("image[0-9].png")
      assert !@parser.is_a_glob?("image.png")
      assert !@parser.is_a_glob?("[]")
      assert !@parser.is_a_glob?("{}")
      assert !@parser.is_a_glob?("{123}")
    end

    def test_words_from_glob
      assert !@parser.words_from_glob("**/*.rb").empty?
      assert !@parser.words_from_glob(".*").include?(".")
      assert !@parser.words_from_glob(".*").include?("..")
    end

    def test_globs_are_alphabetically_ordered
      files = @parser.words_from_glob("*")
      assert_equal files.sort, files
    end

    def test_empty_globs_return_the_glob_pattern
      assert_equal [ "*.nothing" ], @parser.words_from_glob("*.nothing")
    end

    def test_empty_job
      assert @parser.jobs_from('&').empty?
      assert @parser.jobs_from(';').empty?
      assert !@parser.jobs_from('; echo 1').empty?
      assert_equal 2, @parser.jobs_from('; echo 1;;& echo 3').size
    end

    def test_tilde_expansion
      command = @parser.jobs_from('ls ~').first.commands.first
      assert_equal ENV['HOME'], command.args.first

      command = @parser.jobs_from('ls ~/').first.commands.first
      assert_equal "#{ENV['HOME']}/", command.args.first

      command = @parser.jobs_from('ls ~/dir').first.commands.first
      assert_equal "#{ENV['HOME']}/dir", command.args.first

      home = ENV['HOME'].sub(/\/\w+?$/, '')
      command = @parser.jobs_from("ls ~fakeuser/dir/").first.commands.first
      assert_equal "#{home}/fakeuser/dir/", command.args.first

      command = @parser.jobs_from("ls ~fakeuser/").first.commands.first
      assert_equal "#{home}/fakeuser/", command.args.first

      command = @parser.jobs_from("ls ~fakeuser").first.commands.first
      assert_equal "#{home}/fakeuser", command.args.first

      command = @parser.jobs_from("ls no~expand").first.commands.first
      assert_equal "no~expand", command.args.first

      command = @parser.jobs_from('~/bin/hello').first.commands.first
      assert_equal "#{ENV['HOME']}/bin/hello", command.executable
    end

    def test_variable_expansion
      command = @parser.jobs_from("echo $PATH").first.commands.first
      assert_equal ENV['PATH'], command.args.first

      command = @parser.jobs_from("echo $NOT_A_SET_VARIABLE").first.commands.first
      assert_equal "", command.args.first

      command = @parser.jobs_from("echo ${PATH}").first.commands.first
      assert_equal ENV['PATH'], command.args.first

      command = @parser.jobs_from("echo abc$PATH").first.commands.first
      assert_equal "abc$PATH", command.args.first

      command = @parser.jobs_from("echo ${PATH}1234").first.commands.first
      assert_equal "#{ENV['PATH']}1234", command.args.first

      command = @parser.jobs_from("echo 1234${HOME}").first.commands.first
      assert_equal "1234#{ENV['HOME']}", command.args.first

      command = @parser.jobs_from("echo ${PATH}1234${HOME}").first.commands.first
      assert_equal "#{ENV['PATH']}1234#{ENV['HOME']}", command.args.first

      command = @parser.jobs_from("echo $PATH1234").first.commands.first
      assert_equal "", command.args.first
    end

    def test_parsing_environment_variable
      @parser.setup './env_var_writer'
      assert_nil @parser.environment_variable

      @parser.setup 'VAR=123 something'
      assert_equal({ "VAR" => "123" }, @parser.environment_variable)

      @parser.setup 'VAR="123 abc" something'
      assert_equal({ 'VAR' => '123 abc' }, @parser.environment_variable)

      @parser.setup 'VAR= something'
      assert_equal({ 'VAR' => nil }, @parser.environment_variable)
    end

    def test_command_local_environment_variables
      commands = @parser.jobs_from('VAR=123 ./env_var_writer').first.commands
      assert_equal 1, commands.size
      assert_equal Command.new('./env_var_writer'), commands.first
      assert_equal "123", commands.first.environment_variables["VAR"]

      commands = @parser.jobs_from('NUMBERS=123 LETTERS=abc ./env_var_writer').first.commands
      assert_equal 1, commands.size
      assert_equal Command.new('./env_var_writer'), commands.first
      assert_equal "123", commands.first.environment_variables["NUMBERS"]
      assert_equal "abc", commands.first.environment_variables["LETTERS"]

      commands = @parser.jobs_from('NUMBERS=123 ./env_var_writer LETTERS=abc').first.commands
      assert_equal 1, commands.size
      assert_equal Command.new('./env_var_writer') << "LETTERS=abc", commands.first
      assert_equal 1, commands.first.environment_variables.size
      assert_equal "123", commands.first.environment_variables["NUMBERS"]
    end

    def test_alias_expansion
      Urchin::Shell.alias "ls" => "ls --color"

      command = @parser.jobs_from("ls a/dir").first.commands.first
      assert_equal "ls", command.executable
      assert_equal "--color", command.args.first
      assert_equal "a/dir", command.args.last

      Urchin::Shell.alias "ls" => "notls --haha"

      command = @parser.jobs_from("VAR=123 ls a/dir").first.commands.first
      assert_equal "notls", command.executable
      assert_equal "--haha", command.args.first
      assert_equal "a/dir", command.args.last
    ensure
      Urchin::Shell.alias "ls" => nil
    end

    def test_inline_ruby
      jobs = @parser.jobs_from('~@ puts 123 ~@')
      assert_equal 1, jobs.first.commands.size
      ruby = jobs.first.commands.first
      assert ruby.executable.index("ruby")
      assert_equal "-e", ruby.args.first
      assert_equal " puts 123 ", ruby.args.last

      jobs = @parser.jobs_from('echo -n "hello" |~@ puts STDIN.read.reverse ~@')
      assert_equal 2, jobs.first.commands.size
      ruby = jobs.first.commands.last
      assert ruby.executable.index("ruby")
    end
  end
end
