# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/terminal"
require "#{File.dirname(__FILE__)}/urchin_runtime_error"
require "#{File.dirname(__FILE__)}/job_table"

module Urchin

  # Encapsulates a pipeline, which consists of one or more commands.
  class Job
    attr_reader :pids, :status, :title

    def initialize(commands)
      @commands = commands
      @pids = []
    end

    # Checks that every Command is able to be run in a child process or that
    # there is only one Command.
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

        @pids << fork do

          # This process belongs in the same process group as the rest of the
          # pipeline. The process group leader is the first command.
          pid = Process.pid
          pgid = @pids.empty? ? pid : @pids.first
          Process.setpgid(pid, pgid) rescue Errno::EACCES

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

        command.pid = @pids.last
        command.running!

        # Set the process group here as well as in the child process to avoid
        # a race condition.
        #
        # Errno::EACCESS will be raised in whichever process loses the race.
        Process.setpgid(@pids.last, @pids.first) rescue Errno::EACCES

        if nextin != STDIN
          nextin.close
        end
        if nextout != STDOUT
          nextout.close
        end

        nextin = pipe.first
      end

      JOB_TABLE.insert self
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
      Terminal.tcsetpgrp(0, Process.getpgid(@pids.first))
      Process.kill("-CONT", Process.getpgid(@pids.first))

      commands = @commands.find_all { |command| !command.completed? }
      commands.map { |command| command.running! }

      wait_for_children
    end

    # Blocks until all of the running children have changed status.
    def wait_for_children
      commands = @commands.find_all { |command| command.running? }
      commands.each do |command|
        pid, status = Process.waitpid2(command.pid, Process::WUNTRACED)
        if status.stopped?
          command.stopped!
        else
          command.completed!
        end
      end

      if @commands.find_all { |c| !c.completed? }.empty?
        JOB_TABLE.delete self
      else
        @status = :stopped
      end

      # Move the shell back to the foreground.
      Terminal.tcsetpgrp(0, Process.getpgrp)
    end
  end
end
