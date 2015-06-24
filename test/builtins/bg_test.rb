require_relative "../helpers"
require "fileutils"

module Urchin
  describe "Bg" do
    include TestHelpers

    def test_validate_arguments
      jobs = Builtins::Bg.new(JobTable.new)
      jobs.valid_arguments?
      jobs << "--hello"
      assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
      jobs << "--hello"
      assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
    end

    def test_execute_with_no_backgrounded_jobs
      assert_raises(UrchinRuntimeError) { Builtins::Bg.new(JobTable.new).execute }
    end

    def test_execute_no_arguments
      job_table = JobTable.new
      job = TestHelpers::JobForTest.new
      job_table.insert job

      Builtins::Bg.new(job_table).execute
      assert job.background
    end

    def test_execute_with_job_id
      job_table = JobTable.new
      job = TestHelpers::JobForTest.new
      job_table.insert job
      job_table.insert TestHelpers::JobForTest.new

      bg = Builtins::Bg.new(job_table) << "%1"
      bg.execute
      assert job.background
    end
  end
end
