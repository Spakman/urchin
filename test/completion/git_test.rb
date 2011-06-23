require "#{File.dirname(__FILE__)}/../helpers"
require "#{File.dirname(__FILE__)}/../../completion/git"

module Urchin
  module Completion

    class Git
      class << self
        attr_reader :commands
      end
    end

    class GitTestCase < Test::Unit::TestCase
      def test_commands_with_empty_first_arg
        assert_equal Git.commands, Git.complete((Command.create("git", nil)), "")
      end

      def test_commands_with_partial_first_arg
        assert_equal %w( checkout ), Git.complete((Command.create("git", nil) << "checko"), "checko")
      end

      def test_checkout
        Dir.chdir("#{File.dirname(__FILE__)}/../../") do
          begin
            `git branch my-completion-test-branch`
            branches = `git branch --no-color`.gsub(/^[ *] /, "").split("\n")

            assert_equal %w( master my-completion-test-branch ), Git.complete((Command.create("git", nil) << "checkout" << "m"), "m")
            assert_equal [], Git.complete((Command.create("git", nil) << "checkout" << "-b"), "")
          ensure
            `git br -D my-completion-test-branch`
          end
        end
      end
    end
  end
end
