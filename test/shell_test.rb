require "helpers"
require "fileutils"

module Urchin
  class ShellTestCase < Test::Unit::TestCase
    def test_setting_a_prompt
      Urchin::Shell.prompt { "hello" }
      Urchin::Shell.prompt { Time.now.usec }
      shell, shell2 = Urchin::Shell.new, Urchin::Shell.new
      prompt = shell.prompt
      assert_not_equal prompt, shell2.prompt
    ensure
      shell.history.cleanup
      shell2.history.cleanup
      FileUtils.rm_f History::FILE
    end

    def test_setting_alias
      shell = Urchin::Shell.new
      assert_nil shell.aliases["ls"]
      Urchin::Shell.alias "ls" => "ls --color"
      assert_equal "ls --color", shell.aliases["ls"]
    ensure
      shell.history.cleanup
      FileUtils.rm_f History::FILE
    end

    def test_eval
      assert_equal "123", Shell.new.eval("echo -n 123")
    end
  end
end
