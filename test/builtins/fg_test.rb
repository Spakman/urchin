require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/../helpers"
require "#{File.dirname(__FILE__)}/../../builtins/jobs"


module Urchin
  module Builtins

    class JobForFgTest
      attr_accessor :foreground
      def foreground!; @foreground = true; end
    end

    class FgTestCase < Test::Unit::TestCase
      include TestHelpers

      def test_validate_arguments
        jobs = Fg.new(JobTable.new)
        assert_nothing_raised { jobs.valid_arguments? }
        jobs.append_arguments [ "--hello" ]
        assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
      end

      def test_execute_with_no_backgrounded_jobs
        assert_raises(UrchinRuntimeError) { Fg.new(JobTable.new).execute }
      end

      def test_execute_backgrounded_job
        job_table = JobTable.new
        job = JobForFgTest.new
        job_table.insert job
        assert_nothing_raised { Fg.new(job_table).execute }
        assert job.foreground
      end
    end
  end
end
