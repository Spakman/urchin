require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/../helpers"
require "#{File.dirname(__FILE__)}/../../builtins/jobs"


module Urchin
  module Builtins
    class FgTestCase < Test::Unit::TestCase
      include TestHelpers

      def test_validate_arguments
        jobs = Fg.new(JobTable.new)
        assert_nothing_raised { jobs.valid_arguments? }
        jobs.append_arguments [ "--hello" ]
        assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
        jobs.append_arguments [ "--hello" ]
        assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
      end

      def test_execute_with_no_backgrounded_jobs
        assert_raises(UrchinRuntimeError) { Fg.new(JobTable.new).execute }
      end

      def test_execute_no_arguments
        job_table = JobTable.new
        job = JobForTest.new
        job_table.insert job

        assert_nothing_raised { Fg.new(job_table).execute }
        assert job.foreground
      end

      def test_execute_with_job_id
        job_table = JobTable.new
        job = JobForTest.new
        job_table.insert job
        job_table.insert JobForTest.new

        fg = Fg.new(job_table)
        fg.append_arguments [ "%1" ]

        assert_nothing_raised { fg.execute }
        assert job.foreground
      end
    end
  end
end
