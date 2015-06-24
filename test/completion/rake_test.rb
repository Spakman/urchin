require "ostruct"
require_relative "../helpers"

module Urchin
  module Completion

    class RakeTestCommand
      attr_accessor :args, :shell
      def initialize
        @args = []
        @shell = Shell.new
      end
    end

    describe "Rake" do
      def test_commands_with_empty_first_arg
        command = RakeTestCommand.new
        command.send(:extend, Rake)
        assert_equal %w( build test todo ), command.complete("")
      end

      def test_commands_with_multiple_args
        command = RakeTestCommand.new
        command.args << "build"
        command.send(:extend, Rake)
        assert_nil command.complete("")
      end
    end
  end
end
