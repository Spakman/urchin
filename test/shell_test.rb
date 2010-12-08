require "test/unit"
require "#{File.dirname(__FILE__)}/helpers"
require "fileutils"

module Urchin
  class ShellTestCase < Test::Unit::TestCase
    def teardown
      Readline::HISTORY.to_a.size.times do
        Readline::HISTORY.pop
      end
      FileUtils.rm_f URCHIN_HISTORY
    end

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

    def test_history_file_is_written_to
      shell = Urchin::Shell.new
      shell.setup_history

      shell.add_to_history("this is in the history")
      assert_equal 1, File.readlines(URCHIN_HISTORY).size
      shell.add_to_history("this is in the history")
      assert_equal 1, File.readlines(URCHIN_HISTORY).size

      shell.add_to_history("")
      assert_equal 1, File.readlines(URCHIN_HISTORY).size

      shell.add_to_history("hello")
      assert_equal 2, File.readlines(URCHIN_HISTORY).size

      shell.add_to_history("this is in the history")
      assert_equal 3, File.readlines(URCHIN_HISTORY).size
    end

    def test_readline_history_is_populated_from_history_file
      File.open(URCHIN_HISTORY, "w+") do |history|
        history << "the\n"
        history << "history\n"
        history << "is\n"
        history << "populated\n"
      end

      shell = Urchin::Shell.new
      shell.setup_history

      assert_equal "the", Readline::HISTORY.to_a.first
      assert_equal "populated", Readline::HISTORY.to_a.last
      assert_equal 4, Readline::HISTORY.to_a.size
    end
  end
end
