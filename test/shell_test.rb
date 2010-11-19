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
  end
end
