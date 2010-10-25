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
    def self.create(executable, job_table)
      constant = executable.capitalize
      if(Builtins.constants & [ constant, constant.to_sym ]).empty?
        new executable
      else
        Builtins.const_get(constant.to_sym).new(job_table)
      end
    end

    def <<(argument)
      @args << argument
      self
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
