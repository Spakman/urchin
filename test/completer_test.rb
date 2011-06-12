require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/completer"
require "fileutils"

module Urchin
  class CompleterTestCase < Test::Unit::TestCase

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
      # Test that Completer#complete_executable is called.
      Readline.module_eval do
        def self.line_buffer
          "st"
        end
      end
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      assert_equal %w( stdout_stderr_writer stdin_writer ), completer.completion_proc.call("st")

      # Test that FILENAME_COMPLETION_PROC is called.
    end

    def test_filename_completion_proc_is_called_for_second_word
      Readline.module_eval do
        def self.line_buffer
          "stdin_writer p"
        end
      end
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal %w( parser_test.rb ), completer.completion_proc.call("p")
      end

      Readline.module_eval do
        def self.line_buffer
          "stdin_writer "
        end
      end
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal (Dir.entries(".") - [ ".", ".." ]), completer.completion_proc.call("")
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_dot
      Readline.module_eval do
        def self.line_buffer
          "./p"
        end
      end
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal %w( ./parser_test.rb ), completer.completion_proc.call("./p")
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_slash
      dir = File.expand_path(File.dirname(__FILE__))
      Readline.module_eval do
        def self.line_buffer
          File.expand_path(File.dirname(__FILE__))
        end
      end
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      Dir.chdir(dir) do
        assert_equal [ dir ], completer.completion_proc.call(dir)
      end
    end

    def test_filename_completion_proc_is_called_for_lines_starting_with_a_tilde
      Readline.module_eval do
        def self.line_buffer
          "~notalikelyrealuser"
        end
      end
      FileUtils.touch("#{@completer_dir}/~notalikelyrealuser")
      FileUtils.chmod(0744, "#{@completer_dir}/~notalikelyrealuser")

      completer = Completer.new "#{File.expand_path(File.dirname(__FILE__))}:#{@completer_dir}"
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_nil completer.completion_proc.call("~notalikelyrealuseruser")
      end
    end
  end
end
