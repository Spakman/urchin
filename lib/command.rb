# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class Command
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
  end
end
