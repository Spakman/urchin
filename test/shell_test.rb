require "test/unit"
require "#{File.dirname(__FILE__)}/helpers"

module Urchin
  class ShellTestCase < Test::Unit::TestCase
    def test_setting_a_prompt
      Urchin::Shell.prompt { "hello" }
      Urchin::Shell.prompt { Time.now.usec }
      prompt = Urchin::Shell.new.prompt
      assert_not_equal prompt, Urchin::Shell.new.prompt
    end

    def test_setting_alias
      shell = Urchin::Shell.new
      assert_nil shell.aliases["ls"]
      Urchin::Shell.alias "ls" => "ls --color"
      assert_equal "ls --color", shell.aliases["ls"]
    end
  end
end
