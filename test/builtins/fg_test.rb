require "helpers"
require "fileutils"

module Urchin
  class FgTestCase < Test::Unit::TestCase
    include TestHelpers

    def test_validate_arguments
      jobs = Builtins::Fg.new(JobTable.new)
      assert_nothing_raised { jobs.valid_arguments? }
      jobs << "--hello"
      assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
      jobs << "--hello"
      assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
    end

    def test_execute_with_no_backgrounded_jobs
      assert_raises(UrchinRuntimeError) { Builtins::Fg.new(JobTable.new).execute }
    end

    def test_execute_no_arguments
      job_table = JobTable.new
      job = JobForTest.new
      job_table.insert job

      assert_nothing_raised { Builtins::Fg.new(job_table).execute }
      assert job.foreground
    end

    def test_execute_with_job_id
      job_table = JobTable.new
      job = JobForTest.new
      job_table.insert job
      job_table.insert JobForTest.new

      fg = Builtins::Fg.new(job_table) << "%1"

      assert_nothing_raised { fg.execute }
      assert job.foreground
    end
  end
end
