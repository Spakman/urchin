require_relative "helpers"
require "fileutils"
require "ostruct"

module Urchin
  class Shell
    def self.aliases=(aliases)
      @@aliases = aliases
    end
  end

  describe "History" do
    def setup
      @shell = Shell.new
      Readline::HISTORY.length.times do
        Readline::HISTORY.pop
      end
    end

    def teardown
      FileUtils.rm_f History::FILE
    end

    def marshal_to_history(inputs)
      inputs.map! do |input|
        line = OpenStruct.new
        line.input = input
        line
      end

      FileUtils.rm_f History::FILE
      File.open(History::FILE, "w") do |history|
        history << Marshal.dump(inputs)
      end
    end

    def test_history_file_is_written_to
      history = Urchin::History.new(@shell)

      size = File.size(History::FILE)
      history.append(OpenStruct.new(input: "this is in the history"))
      assert File.size(History::FILE) > size

      size = File.size(History::FILE)
      history.append(OpenStruct.new(input: "this is in the history"))
      assert_equal size, File.size(History::FILE)

      history.append(OpenStruct.new(input: ""))
      assert_equal size, File.size(History::FILE)

      size = File.size(History::FILE)
      history.append(OpenStruct.new(input: "hello"))
      assert File.size(History::FILE) > size

      size = File.size(History::FILE)
      history.append(OpenStruct.new(input: "this is in the history"))
      assert File.size(History::FILE) > size
    ensure
      history.cleanup
    end

    def test_readline_history_is_populated_from_history_file
      marshal_to_history %w( the history is populated )

      history = Urchin::History.new(@shell)

      assert_equal %w( the history is populated ), Readline::HISTORY.to_a
    ensure
      history.cleanup
    end

    def test_history_file_is_truncated_file_if_it_is_too_long
      marshal_to_history %w( the history is populated )
      history = Urchin::History.new(@shell)
      history.append OpenStruct.new(input: "again")

      lines = Marshal.load(File.read(History::FILE))
      assert_equal Urchin::History::LINES_TO_STORE, lines.size
      assert_equal "again", lines.last.input
    ensure
      history.cleanup
    end

    def test_fields
      lines = []
      lines <<  OpenStruct.new(input: "hello", date: Time.now, notes: "Clouds are interesting")
      lines <<  OpenStruct.new(input: "hello", date: Time.now, more_notes: "Balance, awareness and peace")
      File.open(History::FILE, "w") do |history|
        history << Marshal.dump(lines)
      end

      assert_equal Set.new([ :input, :date, :notes, :more_notes ]), History.new(@shell).fields
    end
  end
end
