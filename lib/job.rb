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

        if nextin != STDIN
          nextin.close
        end
        if nextout != STDOUT
          nextout.close
        end

        nextin = pipe.first
      end

      @shell.job_table.insert self
      @status = :running

      unless start_in_background?
        foreground!
      end
    end

    def start_in_background!
      @start_in_background = true
    end

    def start_in_background?
      @start_in_background
    end

    # Move this process group to the foreground.
    def foreground!
      Termios.tcsetpgrp(STDIN, Process.getpgid(@pgid))
      Process.kill("-CONT", Process.getpgid(@pgid))
      Termios.tcsetattr(STDIN, Termios::TCSANOW, @terminal_modes)

      commands = @commands.find_all { |command| !command.completed? }
      commands.map { |command| command.running! }

      reap_children

      # Move the shell back to the foreground.
      Termios.tcsetpgrp(STDIN, Process.getpgrp)
      @terminal_modes = Termios.tcgetattr(STDIN)
      Termios.tcsetattr(STDIN, Termios::TCSANOW, @shell.terminal_modes)
    end

    # Collect and process child status changes.
    #
    # This is called with Process::WUNTRACED when a foreground job is waiting
    # for children and with Process::WNOHANG by the SIGCHLD handler in Shell,
    # which catches exiting commands that are part of background jobs.
    def reap_children(flags = Process::WUNTRACED)
      commands = @commands.find_all { |command| command.running? }
      commands.each do |command|
        pid, status = Process.waitpid2(command.pid, flags) rescue Errno::ECHILD
        if pid
          if status.stopped?
            command.stopped!
          else
            command.completed!
          end
        end
      end

      if @commands.find_all { |c| !c.completed? }.empty?
        @shell.job_table.delete self
      elsif flags == Process::WUNTRACED
        @status = :stopped
      end
    end
  end
end
