require "ostruct"
require_relative "../helpers"

module Urchin
  module Completion
    describe "Git" do

      def setup
        @command = Command.create("git", OpenStruct.new(shell: Shell.new))
        @command.send(:extend, Git)
      end

      def test_commands_with_empty_first_arg
        assert_equal Git.commands.to_a, @command.complete("")
      end

      def test_commands_with_partial_first_arg
        @command << "checko"
        assert_equal %w( checkout ), @command.complete("checko")
      end

      def test_checkout
        Dir.chdir("#{File.dirname(__FILE__)}/../../") do
          begin
            `git branch my-completion-test-branch`

            @command << "checkout" << "m"
            assert @command.complete("m").include? "master"
            assert @command.complete("m").include? "my-completion-test-branch"
          ensure
            `git branch -D my-completion-test-branch`
          end
        end
      end
    end
  end
end
