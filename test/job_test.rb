require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/job"
require "#{File.dirname(__FILE__)}/../lib/command"

module RSH
  class JobTestCase < Test::Unit::TestCase

    include TestHelpers

    def test_job_pipeline_has_correct_output_and_closes_pipes
      output = with_redirected_output do
        cat = Command.new("cat")
        cat.append_argument "COPYING"
        cat.append_argument "README"
        grep = Command.new("grep")
        grep.append_argument "-i"
        grep.append_argument "copyright"
        wc = Command.new("wc")
        wc.append_argument "-l"

        job = Job.new([ cat, grep , wc ])
        job.run
      end
      assert_equal "31", output.chomp

      # For some reason test/unit always seems to have a pipe open, which is
      # irritating when you're testing that pipes are closed!
      assert_equal 4, (Dir.entries("/dev/fd/") - [ ".", ".." ]).size
    end

    def test_processes_are_put_in_correct_process_group
      s1 = Command.new("sleep")
      s1.append_argument "1"
      s2 = Command.new("sleep")
      s2.append_argument "1"

      job = Job.new([ s1, s2 ])
      Thread.new do
        job.run
      end
      sleep 0.2

      assert_equal Process.getpgid(job.pids.first), Process.getpgid(job.pids.last)
      assert_equal job.pids.first, Process.getpgid(job.pids.last)
      assert_not_equal Process.getpgrp, Process.getpgid(job.pids.last)

      # ensure the Job process group is in the foreground
      assert_equal job.pids.first, Terminal.tcgetpgrp(0)

      sleep 1

      # ensure this process is back in the foreground
      assert_equal Process.pid, Terminal.tcgetpgrp(0)
    end
  end
end
