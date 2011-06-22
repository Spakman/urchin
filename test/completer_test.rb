require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/readline"
require "#{File.dirname(__FILE__)}/../lib/completer"
require "fileutils"

module Urchin
  class CompleterTestCase < Test::Unit::TestCase

    def set_line_buffer(string)
      Readline.module_eval <<-EVAL
        def self.line_buffer
          "#{string}"
        end
      EVAL
      RbReadline.module_eval <<-EVAL
        @rl_point = #{string.length}
      EVAL
    end

    def setup
      @completer_dir = File.expand_path("#{File.dirname(__FILE__)}/empty_dir")
      FileUtils.mkdir(@completer_dir)
    end

    def teardown
      Readline.module_eval do
        def self.line_buffer
          RbReadline.rl_line_buffer
        end
      end
      FileUtils.rm_r(@completer_dir)
    end

    def test_build_executables_list_from_path
      completer = Completer.new "#{File.expand_path(File.dirname(__FILE__))}:#{@completer_dir}"
      assert_equal 3, completer.instance_eval("@executables").size
    end

    def test_completion_proc_calls_complete_executable_on_first_word
      set_line_buffer "st"
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      assert_equal %w( stdout_stderr_writer stdin_writer ), completer.completion_proc.call("st")
    end

    def test_filename_completion_proc_is_called_for_second_word
      set_line_buffer "stdin_writer p"
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal %w( parser_test.rb ), completer.completion_proc.call("p")
      end

      set_line_buffer "stdin_writer "
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal (Dir.entries(".") - [ ".", ".." ]), completer.completion_proc.call("")
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_dot
      set_line_buffer "./p"
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal %w( ./parser_test.rb ), completer.completion_proc.call("./p")
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_slash
      dir = File.expand_path(File.dirname(__FILE__))
      set_line_buffer File.expand_path(File.dirname(__FILE__))
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      Dir.chdir(dir) do
        assert_equal [ dir ], completer.completion_proc.call(dir)
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_tilde
      set_line_buffer "~notalikelyrealuser"
      FileUtils.touch("#{@completer_dir}/~notalikelyrealuser")
      FileUtils.chmod(0744, "#{@completer_dir}/~notalikelyrealuser")

      completer = Completer.new "#{File.expand_path(File.dirname(__FILE__))}:#{@completer_dir}"
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_nil completer.completion_proc.call("~notalikelyrealuseruser")
      end
    end
  end
end
