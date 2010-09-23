require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/../lib/job"

module RSH
  class JobTestCase < Test::Unit::TestCase
    def teardown
      FileUtils.rm_r("/tmp/rsh.test_unit")
    end

    def redirect_stdout
      FileUtils.mkdir("/tmp/rsh.test_unit")
      @old_stdout = STDOUT.dup
      @redirected_stdout = File.open("/tmp/rsh.test_unit/stdout", "w+")
      STDOUT.reopen @redirected_stdout
    end

    def reopen_stdout
      STDOUT.reopen @old_stdout
      @old_stdout.close
      @redirected_stdout.rewind
      output = @redirected_stdout.read
      @redirected_stdout.close
      return output
    end

    def test_job_pipeline_has_correct_output_and_closes_pipes
      redirect_stdout
      job = Job.new("cat COPYING README | grep -i copyright | wc -l")
      job.run
      job.pids.each do |pid|
        Process.wait pid
      end
      output = reopen_stdout
      assert_equal "31", output.chomp

      # For some reason test/unit always seems to have a pipe open, which is
      # irritating when you're testing that pipes are closed!
      assert_equal 4, (Dir.entries("/dev/fd/") - [ ".", ".." ]).size
    end
  end
end
