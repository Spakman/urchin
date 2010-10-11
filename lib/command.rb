# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class Command
    attr_accessor :pid

    def initialize(executable)
      @executable = executable
      @args = []
    end

    # Returns a new Command or an instance of one of the classes in Builtins.
    def self.create(executable)
      builtin_constant = executable.capitalize
      if Builtins.constants.include? builtin_constant
        Builtins.const_get(builtin_constant.to_sym).new
      else
        new executable
      end
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

    def stopped?
      @status == :stopped
    end

    def completed?
      @status == :completed
    end

    def to_s
      "#{@executable} #{@args.join(" ")}"
    end
  end
end
