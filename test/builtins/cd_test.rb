require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/../helpers"
require "#{File.dirname(__FILE__)}/../../builtins/cd"

module Urchin
  module Builtins
    class Cd
      # Clean the environment for the tests.
      def reset_last_dir
        @@last_dir = nil
      end
    end

    class CdTestCase < Test::Unit::TestCase
      def setup
        @dir = Dir.getwd
      end

      def teardown
        Dir.chdir @dir
        FileUtils.rm_f URCHIN_LAST_CD
        Cd.new(nil).reset_last_dir
      end

      def test_validate_arguments
        assert_nothing_raised { Cd.new(JobTable.new).valid_arguments? }

        cd = Cd.new(JobTable.new) << "/"
        assert_nothing_raised { cd.valid_arguments? }

        cd << "/another"
        exception = assert_raises(UrchinRuntimeError) { cd.valid_arguments? }
        assert_equal "Too many arguments.", exception.message
      end

      def test_no_parameters
        cd = Cd.new(JobTable.new)
        assert_nothing_raised { cd.execute }
        assert_equal ENV["HOME"], Dir.getwd
      end

      def test_one_parameter
        cd = Cd.new(JobTable.new) << "/"
        assert_nothing_raised { cd.execute }
        assert_equal "/", Dir.getwd
      end

      def test_last_directory
        dir = Dir.getwd
        cd = Cd.new(JobTable.new) << "-"

        exception = assert_raises(UrchinRuntimeError) { cd.execute }
        assert_equal "There is no previous directory.", exception.message
        assert_equal dir, Dir.getwd

        cd = Cd.new(JobTable.new) << File.dirname(__FILE__)
        assert_nothing_raised { cd.execute }
        assert_not_equal dir, Dir.getwd

        cd = Cd.new(JobTable.new) << "-"
        assert_nothing_raised { cd.execute }
        assert_equal dir, Dir.getwd
      end

      def test_permission_denied
        FileUtils.mkdir("noperms", :mode => 400)
        cd = Cd.new(JobTable.new) << "noperms"
        exception = assert_raises(UrchinRuntimeError) { cd.execute }
        assert_equal "Permission denied.", exception.message
      ensure
        FileUtils.rm_r("noperms")
      end

      def test_no_directory
        cd = Cd.new(JobTable.new) << "/this/does/not/exist"
        exception = assert_raises(UrchinRuntimeError) { cd.execute }
        assert_equal "Not a directory.", exception.message
      end

      def test_not_a_directory
        cd = Cd.new(JobTable.new) << File.expand_path(__FILE__)
        exception = assert_raises(UrchinRuntimeError) { cd.execute }
        assert_equal "Not a directory.", exception.message
      end

      def test_directory_is_written_to_temporary_file
        cd = Cd.new(JobTable.new) << "/"
        assert_nothing_raised { cd.execute }
        assert_equal "/", File.read(URCHIN_LAST_CD).chomp

        cd = Cd.new(JobTable.new) << "/tmp"
        assert_nothing_raised { cd.execute }
        assert_equal "/tmp", File.read(URCHIN_LAST_CD).chomp

        cd = Cd.new(JobTable.new) << "/not/a/directory"
        begin
          cd.execute
        rescue UrchinRuntimeError
        end
        assert_equal "/tmp", File.read(URCHIN_LAST_CD).chomp
      end
    end
  end
end
