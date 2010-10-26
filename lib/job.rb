# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "termios"
require "#{File.dirname(__FILE__)}/urchin_runtime_error"

module Urchin

  # Encapsulates a pipeline, which consists of one or more commands.
  class Job
    attr_accessor :id
    attr_reader :pgid, :status, :title

    def initialize(commands, shell)
      @commands = commands
      @shell = shell
      @pgid = nil
      @terminal_modes = Termios.tcgetattr(STDIN)
    end

    # Checks that every Command is able to be run in a child process.
    #
    # A pipeline only fails this test when one or more of the commands are a
    # Builtin.
    def valid_pipeline?
      @commands.find_all { |c| c.kind_of? Command } == @commands
    end

    def title
      @commands.first.to_s
    end

    def run
      if valid_pipeline?
        run_pipeline
      else
        if @commands.size == 1
          @commands.first.execute
        else
          raise UrchinRuntimeError.new("Builtins cannot be part of a pipeline.")
        end
      end
    end

    def fork_and_exec(command, nextin, nextout)
      pid = fork do
        # This process belongs in the same process group as the rest of the
        # pipeline. The process group leader is the first command.
        @pgid = pid if @pgid.nil?
        Process.setpgid(Process.pid, @pgid) rescue Errno::EACCES

        Signal.trap :TSTP, "DEFAULT"

        if nextin != STDIN
          STDIN.reopen nextin
          nextin.close
        end
        if nextout != STDOUT
          STDOUT.reopen nextout
          nextout.close
        end

        command.execute
      end

      @pgid = pid if @pgid.nil?

      command.pid = pid
      command.running!

      # Set the process group here as well as in the child process to avoid
      # a race condition.
      #
      # Errno::EACCESS will be raised in whichever process loses the race.
      Process.setpgid(pid, @pgid) rescue Errno::EACCES
    end

    # Builds a pipeline of programs, fork and exec'ing as it goes.
    def run_pipeline
      nextin = STDIN
      nextout = STDOUT
      pipe = []

      @commands.each_with_index do |command, index|
        if index+1 < @commands.size
          pipe = IO.pipe
          nextout = pipe.last
        else
          nextout = STDOUT
        end

        fork_and_exec(command, nextin, nextout)

        nextin.close if nextin != STDIN
        nextout.close if nextout != STDOUT
        nextin = pipe.first
      end

      @shell.job_table.insert self

      running!
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
      Process.kill("-CONT", Process.getpgid(@pgid))
      mark_as_running!
    end

    # Move this process group to the foreground.
    def foreground!
      Termios.tcsetpgrp(STDIN, Process.getpgid(@pgid))
      Termios.tcsetattr(STDIN, Termios::TCSADRAIN, @terminal_modes)
      Process.kill("-CONT", Process.getpgid(@pgid))

      mark_as_running!
      reap_children # This call blocks until the running children change state.

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
    # which catches exiting commands that are part of background jobs.
    def reap_children(flags = Process::WUNTRACED)
      running_commands.each do |command|
        pid, status = Process.waitpid2(command.pid, flags) rescue Errno::ECHILD
        if pid
          if status.stopped?
            command.stopped!
          else
            command.completed!
          end
        end
      end

      if uncompleted_commands.empty?
        # All of the commands are completed so we must be done.
        @shell.job_table.delete self
      elsif flags == Process::WUNTRACED
        # We were also collecting status information for stopped processes, so
        # we must be stopped.
        stopped!
      end
    end

    def uncompleted_commands
      @commands.find_all { |c| !c.completed? }
    end

    def running_commands
      @commands.find_all { |c| c.running? }
    end

    # Mark this job and all the uncompleted commands as running.
    def mark_as_running!
      uncompleted_commands.map { |c| c.running! }
      running!
    end

    def running!
      @status = :running
    end

    def stopped!
      @status = :stopped
    end

    def running?
      @status == :running
    end

    def stopped?
      @status == :stopped
    end
  end
end
