require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/command"

module Urchin
  class CommandTestCase < Test::Unit::TestCase

    include TestHelpers

    class Urchin::Command
      attr_reader :args
    end

    def setup
      @old_dir = Dir.getwd
      Dir.chdir File.dirname(__FILE__)
    end

    alias_method :old_teardown, :teardown

    def teardown
      Dir.chdir @old_dir
      old_teardown
    end

    def test_executing_a_command
      output = with_redirected_output do
        command = Command.create("echo", JobTable.new)
        command << "123"

        pid = fork do
          command.execute
        end
        Process.wait pid
      end

      assert_equal "123", output.chomp
    end

    def test_create
      assert_kind_of Command, Command.create("ls", JobTable.new)
      assert_kind_of Builtins::Cd, Command.create("cd", JobTable.new)
    end

    def test_to_s
      command = Command.create("sleep", JobTable.new)
      command << "20"
      assert_equal "sleep 20", command.to_s
    end

    def test_appending_an_argument_returns_self
      command = Command.create("sleep", JobTable.new)
      assert_equal command, command << "--hello"
      assert_equal 1, command.args.size
    end

    def test_redirecting_stdout_to_a_file
      command = Command.create("echo", JobTable.new) << "123"
      command.add_redirect(STDOUT, "stdout_testfile", "w")

      pid = fork { command.execute }
      Process.wait pid

      assert_equal "123\n", File.read("stdout_testfile")
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end

    def test_redirecting_stdout_to_a_file_appending
      command = Command.create("echo", JobTable.new) << "123"
      command.add_redirect(STDOUT, "stdout_testfile", "a")

      pid = fork { command.execute }
      Process.wait pid

      # should create the file and write to it
      assert_equal "123\n", File.read("stdout_testfile")

      pid = fork { command.execute }
      Process.wait pid

      # should have appended to the file
      assert_equal "123\n123\n", File.read("stdout_testfile")
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end

    def test_redirecting_stderr_to_stdout
      command = Command.create("./in_out_err_writer", JobTable.new) << "this is out" << "this is err"
      command.add_redirect(STDOUT, "stdout_testfile", "w")
      command.add_redirect(STDERR, STDOUT, "w")

      # TODO: this is a hack.
      #
      # Adding this line ensures that the terminal mode setting tests pass on
      # OS X (probably BSD). I have not yet worked out why, but adding other
      # tests like this with and without STDIN redirects have strange effects.
      #
      # Putting STDIN into nonblocking mode seems to affect the -pendin TTY
      # flag. I'm not sure how to clear it.
      command.add_redirect(STDIN, "/dev/null", "r")

      pid = fork { command.execute }
      Process.wait pid

      assert_match /this is out\n/, File.read("stdout_testfile")
      assert_match /this is err\n/, File.read("stdout_testfile")
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end

    def test_redirecting_a_file_to_stdin
      command = Command.create("./in_out_err_writer", JobTable.new) << "this is out"
      command.add_redirect(STDIN, "stdin_testfile", "r")
      command.add_redirect(STDOUT, "stdout_testfile", "w")

      pid = fork { command.execute }
      Process.wait pid

      assert_match /this is in\n/, File.read("stdout_testfile")
      assert_match /this is out\n/, File.read("stdout_testfile")
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end
  end
end
