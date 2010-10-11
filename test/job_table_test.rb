require "test/unit"
require "fileutils"

require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/job"
require "#{File.dirname(__FILE__)}/../lib/command"

module Urchin
  class JobTable
    def empty!
      @jobs = {}
      @index = 1
    end
  end

  unless defined? JOB_TABLE
    JOB_TABLE = JobTable.new
  end

  class JobTableTestCase < Test::Unit::TestCase
    def teardown
      JOB_TABLE.empty!
    end

    def test_insert
      JOB_TABLE.insert Job.new(Command.create("ls"))
      assert_equal 1, JOB_TABLE.jobs.size
    end

    def test_delete
      ls = Job.new(Command.create("ls"))
      JOB_TABLE.insert ls
      pwd = Job.new(Command.create("pwd"))
      JOB_TABLE.insert pwd

      assert_equal 2, JOB_TABLE.jobs.size
      JOB_TABLE.delete pwd
      assert_equal ls, JOB_TABLE.jobs[1]
    end

    def test_last_job
      ls = Job.new(Command.create("ls"))
      JOB_TABLE.insert ls
      pwd = Job.new(Command.create("pwd"))
      JOB_TABLE.insert pwd

      assert_equal pwd, JOB_TABLE.last_job
    end
  end
end
