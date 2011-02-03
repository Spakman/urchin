require "#{File.dirname(__FILE__)}/../helpers"
require "fileutils"

module Urchin
  module Builtins
    class ExportTestCase < Test::Unit::TestCase
      def setup
        @dir = Dir.getwd
      end

      def teardown
        Dir.chdir @dir
      end

      def test_validate_arguments
        exception = assert_raises(UrchinRuntimeError) { Export.new(JobTable.new).valid_arguments? }
        assert_equal "Requires an argument.", exception.message

        export = Export.new(JobTable.new) << "1" << "2" << "3"
        exception = assert_raises(UrchinRuntimeError) { export.valid_arguments? }
        assert_equal "Argument is malformed.", exception.message

        export = Export.new(JobTable.new) << "VAR-123"
        exception = assert_raises(UrchinRuntimeError) { export.valid_arguments? }
        assert_equal "Argument is malformed.", exception.message

        export = Export.new(JobTable.new) << "VAR" << "=" << "123"
        exception = assert_raises(UrchinRuntimeError) { export.valid_arguments? }
        assert_equal "Argument is malformed.", exception.message

        export = Export.new(JobTable.new) << "VAR=" << "123"
        exception = assert_raises(UrchinRuntimeError) { export.valid_arguments? }
        assert_equal "Argument is malformed.", exception.message

        export = Export.new(JobTable.new) << "VAR" << "=123"
        exception = assert_raises(UrchinRuntimeError) { export.valid_arguments? }
        assert_equal "Argument is malformed.", exception.message

        export = Export.new(JobTable.new) << "VAR=123"
        assert_nothing_raised { export.valid_arguments? }

        export = Export.new(JobTable.new) << "VAR="
        assert_nothing_raised { export.valid_arguments? }

        export = Export.new(JobTable.new) << "VAR=  "
        assert_nothing_raised { export.valid_arguments? }
      end

      def test_correctly_sets_environment_variable
        assert_nil ENV['VAR']
        export = Export.new(JobTable.new) << "VAR=123"
        export.execute
        assert_equal "123", ENV['VAR']
      ensure
        ENV['VAR'] = nil
      end

      def test_correctly_sets_environment_variable_value_is_quoted
        assert_nil ENV['VAR']
        export = Export.new(JobTable.new) << "VAR='this is a variable'"
        export.execute
        assert_equal "this is a variable", ENV['VAR']
      ensure
        ENV['VAR'] = nil
      end

      def test_too_many_arguments
        assert_nil ENV['VAR']
        export = Export.new(JobTable.new) << "VAR=this is a variable"
        assert_raises(UrchinRuntimeError) { export.execute }
        assert_nil ENV['VAR']
      ensure
        ENV['VAR'] = nil
      end

      def test_unset_environment_variable_correctly
        ENV['VAR'] = "123"
        export = Export.new(JobTable.new) << "VAR="
        export.execute
        assert_nil ENV['VAR']
      ensure
        ENV['VAR'] = nil
      end
    end
  end
end
