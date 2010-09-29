require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/command"

module Urchin
  class CommandTestCase < Test::Unit::TestCase

    include TestHelpers

    def test_executing_a_command
      output = with_redirected_output do
        command = Command.new("echo")
        command.append_argument "123"

        pid = fork do
          command.execute
        end
        sleep 0.1
      end

      assert_equal "123", output.chomp
    end
  end
end
