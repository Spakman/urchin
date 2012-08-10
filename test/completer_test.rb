require "helpers"
require "fileutils"

module Readline
  class << self
    remove_method :line_buffer
  end

  def self.line_buffer
    @line_buffer_for_test
  end

  def line_buffer_for_test=(string)
    @line_buffer_for_test = string
    RbReadline.module_eval <<-EVAL
      @rl_point = #{string.length}
    EVAL
  end

  module_function :line_buffer_for_test=
end

module Urchin
  module Completion
    module Mycommand
      def complete(word)
        %w( one two )
      end
    end
  end

  class Completer
    attr_reader :executables
  end

  class CompleterTestCase < Test::Unit::TestCase

    def setup
      Shell.alias "ello" => "ls --color"
      @completer_dir = File.expand_path("#{File.dirname(__FILE__)}/empty_dir")
      FileUtils.mkdir(@completer_dir)
    end

    def teardown
      FileUtils.rm_r(@completer_dir)
    end

    def test_build_executables_list_from_path
      completer = Completer.new "#{File.expand_path(File.dirname(__FILE__))}:#{@completer_dir}", Shell.new
      executables = completer.instance_eval("@executables")
      assert_equal((4 + Builtin.builtins.size), executables.size)
      assert executables.include? "bg"
    end

    def test_completion_proc_calls_complete_executable_on_first_word
      Readline.line_buffer_for_test = "st"
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_equal %w( stdout_stderr_writer stdin_writer ).sort, completer.completion_proc.call("st").sort
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

    def test_filename_completion_proc_is_called_for_executables_starting_with_a_dot
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal %w( ./env_var_writer ./empty_dir ).sort, completer.complete_executable("./e").sort
      end
    end

    def test_filename_completion_proc_is_called_for_executables_starting_with_a_slash
      dir = File.expand_path(File.dirname(__FILE__))
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      Dir.chdir(dir) do
        assert_equal [ dir ], completer.complete_executable(dir)
      end
    end

    def test_filename_completion_proc_is_called_for_executables_starting_with_a_tilde
      FileUtils.touch("#{@completer_dir}/~notalikelyrealuser")
      FileUtils.chmod(0744, "#{@completer_dir}/~notalikelyrealuser")

      completer = Completer.new "#{File.expand_path(File.dirname(__FILE__))}:#{@completer_dir}", Shell.new
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_nil completer.complete_executable("~notalikelyrealuseruser")
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

    def test_executables_are_completed_for_second_command
      Readline.line_buffer_for_test = "ls | st"
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_equal %w( stdout_stderr_writer stdin_writer ).sort, completer.completion_proc.call("st").sort
    end

    def test_executables_are_completed_for_second_command_when_it_is_empty
      Readline.line_buffer_for_test = "ls | "
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      expected_exectables = %w( ello env_var_writer stdout_stderr_writer stdin_writer ) + Builtin.builtins.keys
      assert_equal expected_exectables.sort, completer.completion_proc.call("").sort
    end

    def test_executables_are_completed_for_first_command_of_second_job
      Readline.line_buffer_for_test = "ls & st"
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_equal %w( stdout_stderr_writer stdin_writer ).sort, completer.completion_proc.call("st").sort
    end

    def test_executables_are_completed_for_first_command_of_second_job_when_it_is_empty
      Readline.line_buffer_for_test = "ls & "
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      expected_exectables = %w( ello env_var_writer stdout_stderr_writer stdin_writer ) + Builtin.builtins.keys
      assert_equal expected_exectables.sort, completer.completion_proc.call("").sort
    end

    def test_completion_proc_calls_complete_executable_for_an_alias_to_a_multi_word_command
      Readline.line_buffer_for_test = "e"
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_equal %w( env_var_writer ello export ).sort, completer.completion_proc.call("e").sort
    end

    def test_completion_proc_with_empty_line_buffer
      Readline.line_buffer_for_test = ""
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_equal completer.executables.sort, completer.completion_proc.call("").sort
    end

    def test_completing_environment_variable
      Readline.line_buffer_for_test = "echo $PAT"
      completer = Completer.new File.expand_path(File.dirname(__FILE__)), Shell.new
      assert_equal %w( PATH ), completer.completion_proc.call("PAT").sort
    end
  end
end
