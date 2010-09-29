# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/terminal"

module RSH

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

        # Set the process group here as well as in the child process to avoid
        # a race condition.
        #
        # Errno::EACCESS will be raised in whichever process loses the race.
        Process.setpgid(@pids.last, @pids.first) rescue Errno::EACCES

        # Move this process group to the foreground.
        Terminal.tcsetpgrp(0, Process.getpgid(@pids.first))

        if nextin != STDIN
          nextin.close
        end
        if nextout != STDOUT
          nextout.close
        end

        nextin = pipe.first
      end
      @pids.each do |pid|
        Process.wait pid
      end

      # Move the shell back to the foreground.
      Terminal.tcsetpgrp(0, Process.getpgrp)
    end
  end
end
