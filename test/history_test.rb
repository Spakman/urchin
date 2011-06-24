require "helpers"
require "fileutils"

module Urchin
  class HistoryTestCase < Test::Unit::TestCase
    def teardown
      FileUtils.rm_f History::FILE
    end

    def test_history_file_is_written_to
      history = Urchin::History.new

      history.append("this is in the history")
      assert_equal 1, File.readlines(History::FILE).size
      history.append("this is in the history")
      assert_equal 1, File.readlines(History::FILE).size

      history.append("")
      assert_equal 1, File.readlines(History::FILE).size

      history.append("hello")
      assert_equal 2, File.readlines(History::FILE).size

      history.append("this is in the history")
      assert_equal 3, File.readlines(History::FILE).size
    ensure
      history.cleanup
    end

    def test_readline_history_is_populated_from_history_file
      File.open(History::FILE, "w+") do |history|
        history << "the\n"
        history << "history\n"
        history << "is\n"
        history << "populated\n"
      end

      history = Urchin::History.new

      assert_equal %w( the history is populated ), Readline::HISTORY.to_a
    ensure
      history.cleanup
    end
  end
end
