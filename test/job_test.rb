require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/job"
require "#{File.dirname(__FILE__)}/../lib/command"

module Urchin
  class JobTestCase < Test::Unit::TestCase

    include TestHelpers

    def test_job_pipeline_has_correct_output_and_closes_pipes
      cat = Command.create("cat")
      grep = Command.create("grep")
      wc = Command.create("wc")

      output = with_redirected_output do
        cat.append_argument "COPYING"
        cat.append_argument "README"
        grep.append_argument "-i"
        grep.append_argument "copyright"
        wc.append_argument "-l"

        job = Job.new([ cat, grep , wc ])
        job.run
      end
      assert_equal "31", output.chomp
      assert cat.completed?
      assert grep.completed?
      assert wc.completed?

      # For some reason test/unit always seems to have a pipe open, which is
      # irritating when you're testing that pipes are closed!
      assert_equal 4, (Dir.entries("/dev/fd/") - [ ".", ".." ]).size
    end

    def test_processes_are_put_in_correct_process_group
      s1 = Command.create("sleep")
      s1.append_argument "1"
      s2 = Command.create("sleep")
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

    def test_commands_are_marked_as_stopped
      s1 = Command.create("sleep")
      s1.append_argument "1"
      s2 = Command.create("sleep")
      s2.append_argument "1"

      job = Job.new([ s1, s2 ])
      Thread.new do
        job.run
      end
      sleep 0.2

      assert s1.running?
      assert s2.running?

      Process.kill("-TSTP", s1.pid)
      sleep 0.1

      assert s1.stopped?
      assert s2.stopped?
    end

    def test_validate_pipline
      ls = Command.create("ls")
      tail = Command.create("tail")
      assert Job.new([ ls, tail ]).valid_pipeline?

      cd = Command.create("cd")
      assert !Job.new([ cd ]).valid_pipeline?

      ls = Command.create("ls")
      cd = Command.create("cd")
      assert !Job.new([ ls, cd ]).valid_pipeline?
    end

    def test_running_builtin_as_part_of_a_pipline
      ls = Command.create("ls")
      cd = Command.create("cd")
      assert_raises(UrchinRuntimeError) { Job.new([ ls, cd ]).run }
    end
  end
end
