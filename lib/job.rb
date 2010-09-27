# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

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

        if nextin != STDIN
          nextin.close
        end
        if nextout != STDOUT
          nextout.close
        end

        nextin = pipe.first
      end
    end
  end
end
