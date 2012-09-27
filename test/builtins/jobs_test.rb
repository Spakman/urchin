require_relative "../helpers"
require "fileutils"

module Urchin
  class JobsTestCase < Test::Unit::TestCase
    include TestHelpers

    def test_validate_arguments
      jobs = Builtins::Jobs.new(JobTable.new)
      assert_nothing_raised { jobs.valid_arguments? }
      jobs << "--hello"
      assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
    end

    def test_execute
      output = with_redirected_output do
        Builtins::Jobs.new("JOBS").execute
      end
      assert_equal "JOBS\n", output
    end
  end
end
