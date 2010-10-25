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
  end
end
