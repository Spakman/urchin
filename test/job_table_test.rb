require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/job"
require "#{File.dirname(__FILE__)}/../lib/command"
require "#{File.dirname(__FILE__)}/../lib/shell"
require "fileutils"

module Urchin
  class JobTableTestCase < Test::Unit::TestCase
    include TestHelpers

    def setup
      @shell = Shell.new
      @job_table = @shell.job_table
    end

    def teardown
      old_teardown
      cleanup_history
      @shell.history.cleanup
    end

    def test_insert
      @job_table.insert Job.new(Command.create("ls", @job_table), @shell)
      assert_equal 1, @job_table.jobs.size
    end

    def test_delete
      ls = Job.new(Command.create("ls", @job_table), @shell)
      @job_table.insert ls
      pwd = Job.new(Command.create("pwd", @job_table), @shell)
      @job_table.insert pwd

      assert_equal 2, @job_table.jobs.size
      @job_table.delete pwd
      assert_equal ls, @job_table.jobs.first
    end

    def test_get_job_id
      assert_equal 1, @job_table.get_job_id

      @job_table.insert JobForTest.new
      assert_equal 2, @job_table.get_job_id

      job = JobForTest.new
      @job_table.insert job
      assert_equal 3, @job_table.get_job_id

      @job_table.delete job
      assert_equal 2, @job_table.get_job_id
    end

    def test_find_by_id
      @job_table.insert JobForTest.new
      job = JobForTest.new
      @job_table.insert job
      @job_table.insert JobForTest.new
      assert_equal job, @job_table.find_by_id(2)
    end

    def test_to_s
      job = JobForTest.new
      job.title = "for_test"
      @job_table.insert job
      assert_equal "[1] running     for_test", @job_table.to_s
    end
  end
end
