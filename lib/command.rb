# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class Command
    attr_reader :status
    attr_accessor :pid

    def initialize(executable)
      @executable = executable
      @args = []
    end

    def append_argument(argument)
      @args << argument
    end

    def append_arguments(arguments)
      @args += arguments
    end

    def execute
      exec @executable, *@args
    end

    def running!
      @status = :running
    end

    def stopped!
      @status = :stopped
    end

    def completed!
      @status = :completed
    end

    def running?
      @status == :running
    end
  end
end
