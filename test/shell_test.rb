require "test/unit"
require "#{File.dirname(__FILE__)}/helpers"

module Urchin
  class ShellTestCase < Test::Unit::TestCase
    def test_setting_a_prompt
      Urchin::Shell.prompt { "hello" }
      assert_equal "hello", Urchin::Shell.new.prompt
    end
  end
end
