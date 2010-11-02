require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/job"
require "#{File.dirname(__FILE__)}/../lib/command"
require "#{File.dirname(__FILE__)}/../lib/shell"

module Termios
  class Termios
    # Since, unfortunately:
    #
    #   Termios.tcgetattr(STDIN) != Termios.tcgetattr(STDIN)
    #
    # Override this method in a slightly cheeky way.
    def ==(object)
      if object.kind_of? Termios
        self.inspect == object.inspect
      else
        false
      end
    end
  end
end

module Urchin
  class JobTestCase < Test::Unit::TestCase

    include TestHelpers

    class Urchin::Shell
      attr_reader :job_table
      attr_writer :interactive
    end

    class Urchin::Job; attr_reader :commands; end

    def setup
      @shell = Shell.new
      @shell.interactive = true
      @job_table = @shell.job_table
      Urchin::Command.send(:public_class_method, :new)
    end

    def test_job_pipeline_has_correct_output_and_closes_pipes
      cat = Command.create("cat", @job_table) << "COPYING" << "README"
      grep = Command.create("grep", @job_table) << "-i" << "copyright"
      wc = Command.create("wc", @job_table) << "-l"

      output = with_redirected_output do
        job = Job.new([ cat, grep , wc ], @shell)
        job.run
      end
      assert_equal "31", output.chomp
      assert cat.completed?
      assert grep.completed?
      assert wc.completed?

      # For some reason test/unit always seems to have a pipe open, which is
      # irritating when you're testing that pipes are closed!
      assert_equal 4, (Dir.entries("/dev/fd/") - [ ".", ".." ]).size
      assert_raises(Errno::ECHILD) { Process.wait }
    end

    def test_processes_are_put_in_correct_process_group
      s1 = Command.create("sleep", @job_table) << "0.2"
      s2 = Command.create("sleep", @job_table) << "0.2"

      job = Job.new([ s1, s2 ], @shell)
      Thread.new do
        job.run
      end
      sleep 0.1

      assert_equal Process.getpgid(job.pgid), Process.getpgid(job.commands.last.pid)
      assert_equal job.pgid, Process.getpgid(job.commands.last.pid)
      assert_not_equal Process.getpgrp, job.pgid

      # ensure the Job process group is in the foreground
      assert_equal job.pgid, Termios.tcgetpgrp(STDIN)

      until s1.completed? && s2.completed?
        sleep 0.1
      end

      # ensure this process is back in the foreground
      assert_equal Process.getpgrp, Termios.tcgetpgrp(STDIN)
      assert_raises(Errno::ECHILD) { Process.wait }
    end

    def test_job_is_stopped
      s1 = Command.create("sleep", @job_table) << "1"
      s2 = Command.create("sleep", @job_table) << "1"

      job = Job.new([ s1, s2 ], @shell)
      Thread.new do
        job.run
      end
      sleep 0.1

      assert s1.running?
      assert s2.running?

      Process.kill("-TSTP", job.pgid)
      sleep 0.2

      assert job.stopped?
      assert s1.stopped?
      assert s2.stopped?
      assert_not_equal s1.pid, Termios.tcgetpgrp(STDIN)

    ensure
      Process.kill("-CONT", job.pgid)
      Process.wait rescue Errno::ECHILD
      Process.wait rescue Errno::ECHILD
    end

    def test_background
      s1 = Command.create("sleep", @job_table) << "1"
      s2 = Command.create("sleep", @job_table) << "1"

      job = Job.new([ s1, s2 ], @shell)
      Thread.new do
        job.run
      end
      sleep 0.1

      Process.kill("-TSTP", job.pgid)
      sleep 0.1

      job.background!
      assert job.running?
      assert s1.running?
      assert s2.running?
      assert_not_equal s1.pid, Termios.tcgetpgrp(STDIN)

    ensure
      Process.kill("-CONT", job.pgid)
      Process.wait rescue Errno::ECHILD
      Process.wait rescue Errno::ECHILD
    end

    def test_start_in_background
      s1 = Command.create("sleep", @job_table) << "0.5"
      s2 = Command.create("sleep", @job_table) << "0.5"

      job = Job.new([ s1, s2 ], @shell)
      job.start_in_background!
      Thread.new do
        job.run
      end
      sleep 0.1

      assert s1.running?
      assert s2.running?
      assert_not_equal s1.pid, Termios.tcgetpgrp(STDIN)

      # check the processes are reaped
      sleep 0.5
      assert_raises(Errno::ECHILD) { Process.wait }
      assert s1.completed?
      assert s2.completed?

    ensure
      Process.wait rescue Errno::ECHILD
      Process.wait rescue Errno::ECHILD
    end

    def test_foreground
      s1 = Command.create("sleep", @job_table) << "0.2"
      s2 = Command.create("sleep", @job_table) << "0.2"

      job = Job.new([ s1, s2 ], @shell)
      job.start_in_background!
      Thread.new do
        job.run
      end
      sleep 0.1

      assert_not_equal s1.pid, Termios.tcgetpgrp(STDIN)
      job.foreground!
      assert_raises(Errno::ECHILD) { Process.wait }
      assert s1.completed?
      assert s2.completed?

    ensure
      Process.wait rescue Errno::ECHILD
      Process.wait rescue Errno::ECHILD
    end

    def test_validate_pipline
      ls = Command.create("ls", @job_table)
      tail = Command.create("tail", @job_table)
      assert Job.new([ ls, tail ], @shell).valid_pipeline?

      cd = Command.create("cd", @job_table)
      assert !Job.new([ cd ], @shell).valid_pipeline?

      ls = Command.create("ls", @job_table)
      cd = Command.create("cd", @job_table)
      assert !Job.new([ ls, cd ], @shell).valid_pipeline?
    end

    def test_running_builtin_as_part_of_a_pipline
      ls = Command.create("ls", @job_table)
      cd = Command.create("cd", @job_table)
      assert_raises(UrchinRuntimeError) { Job.new([ ls, cd ], @shell).run }
    end

    def test_title
      ls = Command.create("ls", @job_table)
      cd = Command.create("cd", @job_table)
      assert_equal ls.to_s, Job.new([ ls, cd ], @shell).title
    end

    def test_terminal_modes_are_saved_and_restored
      man = Command.new("less") << File.expand_path(File.dirname(__FILE__))

      job = Job.new([ man ], @shell)
      Thread.new do
        job.run
      end
      sleep 0.1

      assert_not_equal Termios.tcgetattr(STDIN), @shell.terminal_modes

      Process.kill("-TSTP", job.pgid)
      sleep 0.1

      assert_equal Termios.tcgetattr(STDIN), @shell.terminal_modes
      Process.kill(:TERM, job.commands.first.pid)
    end
  end
end
