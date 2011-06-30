require "helpers"
require "fileutils"
require "pathname"

module Urchin
  class Builtins::Cd
    # Clean the environment for the tests.
    def reset_last_dir
      @@previous_dir = nil
    end
  end

  class CdTestCase < Test::Unit::TestCase
    def setup
      @dir = Dir.getwd
    end

    def teardown
      Dir.chdir @dir
      FileUtils.rm_f Builtins::Cd::LAST_DIR
      Builtins::Cd.new(nil).reset_last_dir
    end

    def test_validate_arguments
      assert_nothing_raised { Builtins::Cd.new(JobTable.new).valid_arguments? }

      cd = Builtins::Cd.new(JobTable.new) << "/"
      assert_nothing_raised { cd.valid_arguments? }

      cd << "/another"
      exception = assert_raises(UrchinRuntimeError) { cd.valid_arguments? }
      assert_equal "Too many arguments.", exception.message
    end

    def test_no_parameters
      cd = Builtins::Cd.new(JobTable.new)
      assert_nothing_raised { cd.execute }
      assert_equal ENV["HOME"], Dir.getwd
    end

    def test_one_parameter
      cd = Builtins::Cd.new(JobTable.new) << "/"
      assert_nothing_raised { cd.execute }
      assert_equal "/", Dir.getwd
    end

    def test_last_directory
      dir = Dir.getwd
      cd = Builtins::Cd.new(JobTable.new) << "-"

      exception = assert_raises(UrchinRuntimeError) { cd.execute }
      assert_equal "There is no previous directory.", exception.message
      assert_equal dir, Dir.getwd

      cd = Builtins::Cd.new(JobTable.new) << File.dirname(__FILE__)
      assert_nothing_raised { cd.execute }
      assert_not_equal dir, Dir.getwd

      cd = Builtins::Cd.new(JobTable.new) << "-"
      assert_nothing_raised { cd.execute }
      assert_equal dir, Dir.getwd
    end

    def test_permission_denied
      FileUtils.mkdir("noperms", :mode => 400)
      cd = Builtins::Cd.new(JobTable.new) << "noperms"
      exception = assert_raises(UrchinRuntimeError) { cd.execute }
      assert_equal "Permission denied.", exception.message
    ensure
      FileUtils.rm_r("noperms")
    end

    def test_no_directory
      cd = Builtins::Cd.new(JobTable.new) << "/this/does/not/exist"
      exception = assert_raises(UrchinRuntimeError) { cd.execute }
      assert_equal "Not a directory.", exception.message
    end

    def test_not_a_directory
      cd = Builtins::Cd.new(JobTable.new) << File.expand_path(__FILE__)
      exception = assert_raises(UrchinRuntimeError) { cd.execute }
      assert_equal "Not a directory.", exception.message
    end

    def test_directory_is_written_to_temporary_file
      cd = Builtins::Cd.new(JobTable.new) << "/"
      assert_nothing_raised { cd.execute }
      assert_equal "/", File.read(Builtins::Cd::LAST_DIR).chomp

      path = Pathname.new("/tmp")

      cd = Builtins::Cd.new(JobTable.new) << path.to_s
      assert_nothing_raised { cd.execute }
      assert_equal path.realpath.to_s, File.read(Builtins::Cd::LAST_DIR).chomp

      cd = Builtins::Cd.new(JobTable.new) << "/not/a/directory"
      begin
        cd.execute
      rescue UrchinRuntimeError
      end
      assert_equal path.realpath.to_s, File.read(Builtins::Cd::LAST_DIR).chomp
    end
  end
end
