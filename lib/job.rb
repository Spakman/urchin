# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/terminal"

module Urchin

  # Encapsulates a pipeline, which consists of one or more commands.
  class Job
    attr_reader :pids

    def initialize(commands)
      @commands = commands
      @pids = []
    end

    # Builds a pipeline of programs, fork and exec'ing as it goes.
    def run
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

      # Move this process group to the foreground.
      Terminal.tcsetpgrp(0, Process.getpgid(@pids.first))

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

      # Move the shell back to the foreground.
      Terminal.tcsetpgrp(0, Process.getpgrp)
    end
  end
end
