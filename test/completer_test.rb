require "helpers"
require "fileutils"

module Readline
  attr_accessor :line_buffer_for_test
  module_function :line_buffer_for_test=

  class << self
    remove_method :line_buffer
  end
  def self.line_buffer
    @line_buffer_for_test
  end
end

module Urchin
  module Completion
    class Mycommand
      def complete(command, word)
        %w( one two )
      end
    end
  end

  class CompleterTestCase < Test::Unit::TestCase

    def setup
      @completer_dir = File.expand_path("#{File.dirname(__FILE__)}/empty_dir")
      FileUtils.mkdir(@completer_dir)
    end

    def teardown
      FileUtils.rm_r(@completer_dir)
    end

    def test_build_executables_list_from_path
      completer = Completer.new "#{File.expand_path(File.dirname(__FILE__))}:#{@completer_dir}", Shell.new
      assert_equal 3, completer.instance_eval("@executables").size
    end

    def test_completion_proc_calls_complete_executable_on_first_word
      Readline.line_buffer_for_test = "st"
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_equal %w( stdout_stderr_writer stdin_writer ), completer.completion_proc.call("st")
    end

    def test_filename_completion_proc_is_called_for_second_word
      Readline.line_buffer_for_test = "stdin_writer p"
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal %w( parser_test.rb ), completer.completion_proc.call("p")
      end

      Readline.line_buffer_for_test = "stdin_writer "
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal((Dir.entries(".") - [ ".", ".." ]), completer.completion_proc.call(""))
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_dot
      Readline.line_buffer_for_test = "./p"
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal %w( ./parser_test.rb ), completer.completion_proc.call("./p")
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_slash
      dir = File.expand_path(File.dirname(__FILE__))
      Readline.line_buffer_for_test = File.expand_path(File.dirname(__FILE__))
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      Dir.chdir(dir) do
        assert_equal [ dir ], completer.completion_proc.call(dir)
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_tilde
      Readline.line_buffer_for_test = "~notalikelyrealuser"
      FileUtils.touch("#{@completer_dir}/~notalikelyrealuser")
      FileUtils.chmod(0744, "#{@completer_dir}/~notalikelyrealuser")

      completer = Completer.new "#{File.expand_path(File.dirname(__FILE__))}:#{@completer_dir}", Shell.new
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_nil completer.completion_proc.call("~notalikelyrealuseruser")
      end
    end

    def test_sub_command_completion_is_called
      Readline.line_buffer_for_test = "mycommand o"

      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_equal %w( one two ), completer.completion_proc.call("o")
    end

    def test_sub_command_completion_for_builtin
      Readline.line_buffer_for_test = "cd o"

      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_nil completer.completion_proc.call("o")
    end
  end
end
