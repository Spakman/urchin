require_relative "helpers"
require "fileutils"

module Urchin
  describe "Shell" do
    def test_setting_a_prompt
      Urchin::Shell.prompt { "hello" }
      Urchin::Shell.prompt { Time.now.usec }
      shell, shell2 = Urchin::Shell.new, Urchin::Shell.new
      prompt = shell.prompt
      refute_equal prompt, shell2.prompt
    ensure
      shell.history.cleanup
      shell2.history.cleanup
      FileUtils.rm_f History::FILE
    end

    def test_setting_alias
      shell = Urchin::Shell.new
      assert_nil shell.aliases["ls"]
      shell.alias "ls" => "ls --color"
      assert_equal "ls --color", shell.aliases["ls"]
    ensure
      shell.history.cleanup
      FileUtils.rm_f History::FILE
    end

    def test_eval
      assert_equal "123", Shell.new.eval("echo -n 123")
    end

    def test_urchin_last_time_is_set
      Shell.new.parse_and_run("sleep 0.4")
      assert_equal 0.4, ENV["URCHIN_LAST_TIME"].chop.to_f.round(1)
    end
  end
end
