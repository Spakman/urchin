# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin

  # Encapsulates a pipeline, which consists of one or more commands.
  class Job
    attr_accessor :id
    attr_reader :pgid, :commands

    def initialize(commands, shell)
      @commands = commands
      @shell = shell
      @pgid = nil
      @terminal_modes = Termios.tcgetattr(STDIN) if STDIN.tty?
      @start_in_background = false
    end

    def <<(command)
      @commands << command
    end

    def empty?
      @commands.empty?
    end

    def title
      @commands.first.to_s
    end

    def exec_in_process(command, next_in, next_out)
      old_stdin = STDIN.dup
      old_stdout = STDOUT.dup

      STDIN.reopen next_in
      STDOUT.reopen next_out

      command.execute

      STDIN.reopen old_stdin
      STDOUT.reopen old_stdout

    ensure
      old_stdin.close
      old_stdout.close
    end

    def fork_and_exec(command, next_in, next_out)
      pid = fork do
        # This process belongs in the same process group as the rest of the
        # pipeline. The process group leader is the first command.
        @pgid = Process.pid if @pgid.nil?
        Process.setpgid(Process.pid, @pgid) rescue Errno::EACCES

        Signal.trap :INT, "DEFAULT"
        Signal.trap :QUIT, "DEFAULT"
        Signal.trap :TSTP, "DEFAULT"
        Signal.trap :TTIN, "DEFAULT"
        Signal.trap :TTOU, "DEFAULT"
        Signal.trap :CHLD, "DEFAULT"

        if next_in != STDIN
          STDIN.reopen next_in
          next_in.close
        end
        if next_out != STDOUT
          STDOUT.reopen next_out
          next_out.close
        end

        close_fds

        command.execute
      end

      command.pid = pid
      command.running!

      # Set the process group here as well as in the child process to avoid
      # a race condition.
      #
      # Errno::EACCESS will be raised in whichever process loses the race.
      @pgid = pid if @pgid.nil?
      Process.setpgid(pid, @pgid) rescue Errno::EACCES
    end

    # This closes all file descriptors except STDIN, STDOUT and STDERR.
    def close_fds
      Dir.entries("/dev/fd/").each do |file|
        next if file == '.' || file == '..'
        fd = file.to_i
        next if fd < 3
        IO.new(fd).close rescue Errno::EBADF
      end
    end

    # Builds a pipeline of programs, fork and exec'ing as it goes.
    def run
      next_in = STDIN
      next_out = STDOUT
      pipe = []

      @commands.each_with_index do |command, index|
        if index+1 < @commands.size
          pipe = IO.pipe
          next_out = pipe.last
        else
          next_out = STDOUT
        end

        if command.should_fork?
          fork_and_exec(command, next_in, next_out)
        else
          exec_in_process(command, next_in, next_out)
        end

        next_in.close if next_in != STDIN
        next_out.close if next_out != STDOUT
        next_in = pipe.first
      end

      @shell.job_table.insert self

      foreground! unless start_in_background?
    end

    def start_in_background!
      @start_in_background = true
    end

    def start_in_background?
      @start_in_background
    end

    # Run this process group in the background.
    def background!
      Process.kill("-CONT", @pgid)
      mark_as_running!
    end

    # Move this process group to the foreground.
    #
    # EINVAL and ESRCH are rescued because, in rare cases, process groups may
    # have already completed before execution reaches here.
    def foreground!
      Termios.tcsetpgrp(STDIN, @pgid) rescue Errno::EINVAL
      Termios.tcsetattr(STDIN, Termios::TCSADRAIN, @terminal_modes)
      Process.kill("-CONT", @pgid) rescue Errno::ESRCH

      mark_as_running!
      reap_children(Process::WUNTRACED)

      # Move the shell back to the foreground now that the job is stopped or
      # completed.
      Termios.tcsetpgrp(STDIN, Process.getpgrp)
      @terminal_modes = Termios.tcgetattr(STDIN)
      Termios.tcsetattr(STDIN, Termios::TCSADRAIN, @shell.terminal_modes)
    end

    # Collect and process child status changes.
    #
    # This is called with Process::WUNTRACED when a foreground job is waiting
    # for children and with Process::WNOHANG by the SIGCHLD handler in Shell,
    # which catches exiting commands that are part of background jobs. Flags
    # are passed to waitpid2 directly (and can be a logical OR).
    def reap_children(flags)
      running_commands.each do |command|
        pid, status = Process.waitpid2(command.pid, flags) rescue Errno::ECHILD
        command.change_status status unless pid.nil?
      end

      if uncompleted_commands.empty?
        # All of the commands are completed so we must be done.
        @shell.job_table.delete self
      end
    end

    def uncompleted_commands
      @commands.find_all { |c| !c.completed? }
    end

    def running_commands
      @commands.find_all { |c| c.running? }
    end

    # Mark all the uncompleted commands as running.
    def mark_as_running!
      uncompleted_commands.map { |c| c.running! }
    end

    def running?
      !running_commands.empty?
    end

    def stopped?
      running_commands.empty? && !uncompleted_commands.empty?
    end

    def status
      running? ? :running : :stopped
    end
  end
end
