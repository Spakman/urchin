require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/../../builtins/cd"

module Urchin
  module Builtins
    class CdTestCase < Test::Unit::TestCase
      def setup
        @dir = Dir.getwd
      end

      def teardown
        Dir.chdir @dir
      end

      def test_validate_arguments
        assert_nothing_raised { Cd.new.valid_arguments? }

        cd = Cd.new
        cd.append_arguments [ "/" ]
        assert_nothing_raised { cd.valid_arguments? }

        cd.append_arguments [ "/another" ]
        assert_raises(UrchinRuntimeError) { cd.valid_arguments? }
      end

      def test_no_parameters
        cd = Cd.new
        assert_nothing_raised { cd.execute }
        assert_equal ENV["HOME"], Dir.getwd
      end

      def test_one_parameter
        cd = Cd.new
        cd.append_arguments [ "/" ]
        assert_nothing_raised { cd.execute }
        assert_equal "/", Dir.getwd
      end

      def test_permission_denied
        cd = Cd.new
        cd.append_arguments [ "/root" ]
        assert_raises(UrchinRuntimeError) { cd.execute }
      end
    end
  end
end
