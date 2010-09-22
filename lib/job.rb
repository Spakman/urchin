# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module RSH

  # Encapsulates a pipeline, which consists of one or more programs.
  class Job
    attr_reader :pids

    def initialize(commands)
      @programs = commands.split("|") # really dumb parsing
      @pids = []
    end

    # Builds a pipeline of programs, fork and exec'ing as it goes.
    #
    # TODO: make the exec() safe from shell injection.
    def run
      nextin = STDIN
      nextout = STDOUT
      pipe = []

      @programs.each_with_index do |program, index|
        if index+1 < @programs.size
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
          exec program
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
