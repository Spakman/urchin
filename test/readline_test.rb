require_relative "helpers"
require "fileutils"

module Urchin
  class ReadlineTestCase < Test::Unit::TestCase
    def setup
      RbReadline.module_eval do
        @rl_filename_quote_characters = " |-\\"
      end
    end

    def test_filename_quoting_function_quotes_spaces_and_other_special_characters
      filename = "spaces | - other chars"
      original_filename = filename.dup

      assert_equal "spaces\\ \\|\\ \\-\\ other\\ chars", RbReadline.filename_quoting_function(filename, nil, 0.chr)
      # The original variable should be left untouched.
      assert_equal original_filename, filename
    end

    def test_filename_dequoting_function_dequotes_special_chars
      quoted_filename = "spaces\\ \\|\\ \\-\\ other\\ chars"
      original_filename = quoted_filename.dup

      assert_equal "spaces | - other chars", RbReadline.filename_dequoting_function(quoted_filename, 0.chr)
      # The original variable should be left untouched.
      assert_equal original_filename, quoted_filename
    end

    def test_filename_quoting_function_is_noop_without_backslash
      filename = "'path with spaces'"
      original_filename = filename.dup

      assert_equal "'path with spaces'", RbReadline.filename_quoting_function(filename, nil, "'")
      # The original variable should be left untouched.
      assert_equal original_filename, filename

      filename = '"path with spaces"'
      original_filename = filename.dup

      assert_equal '"path with spaces"', RbReadline.filename_quoting_function(filename, nil, '"')
      # The original variable should be left untouched.
      assert_equal original_filename, filename
    end
  end
end
