require_relative "helpers"
require "fileutils"
require "ruby_reserved_fds"

module Termios
  class Termios
    # Since, unfortunately:
    #
    #   Termios.tcgetattr(STDIN) != Termios.tcgetattr(STDIN)
    #
    # Override this method by checking each of the instance variables.
    def ==(object)
      if object.kind_of? Termios
        object.instance_variables.each do |var|
          unless object.instance_variable_get(var) == instance_variable_get(var)
            return false
          end
        end
        true
      else
        false
      end
    end
  end
end

module Urchin
  module Builtins
    class Builtinecho < Builtin
      EXECUTABLE = "builtinecho"
      def execute
        puts @args.first
      end
    end

    class Reverse < Builtin
      EXECUTABLE = "reverse"
      def execute
        puts STDIN.read.chomp.reverse
      end
    end
  end

  class JobTestCase < Test::Unit::TestCase

    include TestHelpers

    class Urchin::Shell
      attr_writer :interactive
    end

    def setup
      @shell = Shell.new
      @shell.interactive = true
      @job_table = @shell.job_table
      Urchin::Command.send(:public_class_method, :new)
    end

    def teardown
      old_teardown
      cleanup_history
      Process.waitall
    end

    def test_job_pipeline_has_correct_output_and_closes_pipes
      num_fds = (Dir.entries("/dev/fd/") - [ ".", ".." ]).size

      cat = Command.create("cat", @job_table) << "COPYING" << "README"
      grep = Command.create("grep", @job_table) << "-i" << "copyright"
      wc = Command.create("wc", @job_table) << "-l"

      output = with_redirected_output do
        job = Job.new([ cat, grep , wc ], @shell)
        job.run
      end
      assert_equal "31", output.strip
      assert cat.completed?
      assert grep.completed?
      assert wc.completed?

      # For some reason test/unit always seems to have a pipe open, which is
      # irritating when you're testing that pipes are closed!
      assert_equal num_fds, (Dir.entries("/dev/fd/") - [ ".", ".." ]).size
      assert_raises(Errno::ECHILD) { Process.wait }
    end

    def test_processes_are_put_in_correct_process_group
      s1 = Command.create("sleep", @job_table) << "0.2"
      s2 = Command.create("sleep", @job_table) << "0.2"

      job = Job.new([ s1, s2 ], @shell)
      Thread.new do
        job.run
      end
      until s1.running? && s2.running?
        sleep 0.01
      end; sleep 0.1

      assert_equal Process.getpgid(s1.pid), Process.getpgid(s2.pid)
      assert_equal job.pgid, Process.getpgid(s2.pid)
      assert_not_equal Process.getpgrp, job.pgid

      # ensure the Job process group is in the foreground
      assert_equal job.pgid, Termios.tcgetpgrp(STDIN)

      until s1.completed? && s2.completed?
        sleep 0.1
      end; sleep 0.2 # give it time to set the terminal modes

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
      sleep 0.2
      new_job = Job.new([ Command.create("sleep", @job_table) << "2" ], @shell)
      @shell.job_table.insert new_job

      assert s1.running?
      assert s2.running?
      assert_equal :running, job.status

      Process.kill("-TSTP", job.pgid)
      sleep 0.2

      assert job.stopped?
      assert_equal :stopped, job.status
      assert s1.stopped?
      assert s2.stopped?
      assert_not_equal s1.pid, Termios.tcgetpgrp(STDIN)
      assert_equal job, @shell.job_table.jobs.last

    ensure
      Process.kill("-KILL", job.pgid) rescue Errno::ESRCH
    end

    def test_background
      s1 = Command.create("sleep", @job_table) << "1"
      s2 = Command.create("sleep", @job_table) << "1"

      job = Job.new([ s1, s2 ], @shell)
      Thread.new do
        job.run
      end

      sleep 0.01 until s1.running?; sleep 0.1

      Process.kill("-TSTP", job.pgid)

      sleep 0.01 until s1.stopped?; sleep 0.1

      job.background!
      assert job.running?
      assert s1.running?
      assert s2.running?
      assert_not_equal s1.pid, Termios.tcgetpgrp(STDIN)

    ensure
      Process.kill("-KILL", job.pgid) rescue Errno::ESRCH
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
    end

    def test_foreground
      s1 = Command.create("sleep", @job_table) << "0.2"
      s2 = Command.create("sleep", @job_table) << "0.2"

      job = Job.new([ s1, s2 ], @shell)
      job.start_in_background!
      Thread.new do
        job.run
      end
      sleep 0.01 until s1.running?; sleep 0.1

      assert_not_equal s1.pid, Termios.tcgetpgrp(STDIN)
      job.foreground!
      assert_raises(Errno::ECHILD) { Process.wait }
      assert s1.completed?
      assert s2.completed?
    end

    def test_running_builtin_as_part_of_a_pipline
      open_fds = Dir.entries("/dev/fd/")
      builtin_echo = Command.create("builtinecho", @job_table) << "123"
      rev = Command.create("rev", @job_table)
      builtin_reverse = Command.create("reverse", @job_table)
      output = with_redirected_output do
        Job.new([ builtin_echo, rev, builtin_reverse ], @shell).run
      end
      assert_equal "123\n", output
      assert_equal open_fds, Dir.entries("/dev/fd/")
    end

    def test_title
      ls = Command.create("ls", @job_table)
      cd = Command.create("cd", @job_table)
      assert_equal ls.to_str, Job.new([ ls, cd ], @shell).title
    end

    def test_terminal_modes_are_saved_and_restored
      less = Command.create("less", @job_table) << "#{File.dirname(__FILE__)}/../README"

      job = Job.new([ less ], @shell)
      Thread.new do
        job.run
      end

      sleep 0.01 until less.running?
      sleep 0.2 # give it time to set the terminal modes

      assert_not_equal Termios.tcgetattr(STDIN), @shell.terminal_modes

      Process.kill("-TSTP", job.pgid)

      sleep 0.01 until less.stopped?; sleep 0.1

      assert_equal Termios.tcgetattr(STDIN), @shell.terminal_modes
    ensure
      Process.kill(:KILL, less.pid) rescue Errno::ESRCH
    end

    # I don't know how to perform this test cleanly on other platforms.
    if RUBY_PLATFORM =~ /linux/
      def test_shell_history_file_is_closed_after_fork
        sleep = Command.create("sleep", @job_table) << "1"
        Thread.new do
          job = Job.new([ sleep ], @shell)
          job.run
        end
        sleep 0.01 until sleep.running?; sleep 0.01

        fds = Dir.entries("/proc/#{sleep.pid}/fd/") - %w( . .. )
        unreserved_fds = fds.delete_if { |e| not RubyReservedFDs.reserved_fd?(e.to_i) }
        assert_equal 0, unreserved_fds.size
      end
    end
  end
end
