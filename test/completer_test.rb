require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/completer"
require "fileutils"

module Urchin
  class CompleterTestCase < Test::Unit::TestCase

    def test_build_executables_list_from_path
      empty_dir = File.expand_path("#{File.dirname(__FILE__)}/empty_dir")
      FileUtils.mkdir(empty_dir)

      completer = Completer.new "#{File.expand_path(File.dirname(__FILE__))}:#{empty_dir}"
      assert_equal 3, completer.instance_eval("@executables").size

    ensure
      FileUtils.rm_r(empty_dir)
    end

    def test_completion_proc
      # Test that Completer#complete_executable is called.
      Readline.module_eval do
        def self.line_buffer
          "st"
        end
      end
      completer = Completer.new File.expand_path(File.dirname(__FILE__))
      assert_equal %w( stdout_stderr_writer stdin_writer ), completer.completion_proc.call("st")

      # Test that FILENAME_COMPLETION_PROC is called.
      Readline.module_eval do
        def self.line_buffer
          "stdin_writer p"
        end
      end
      Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
        assert_equal %w( parser_test.rb ), completer.completion_proc.call("p")
      end

    ensure
      Readline.module_eval do
        def self.line_buffer
          RbReadline.rl_line_buffer
        end
      end
    end
  end
end
