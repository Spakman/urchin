require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/../helpers"
require "#{File.dirname(__FILE__)}/../../builtins/jobs"


module Urchin
  module Builtins
    class JobsTestCase < Test::Unit::TestCase
      include TestHelpers

      def test_validate_arguments
        jobs = Jobs.new(JobTable.new)
        assert_nothing_raised { jobs.valid_arguments? }
        jobs.append_arguments [ "--hello" ]
        assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
      end

      def test_execute
        output = with_redirected_output do
          Jobs.new("JOBS").execute
        end
        assert_equal "JOBS\n", output
      end
    end
  end
end
