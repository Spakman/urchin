# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin

  # An abstract base class for all types of command (processes, builtins and
  # shell functions).
  class Command
    private_class_method :new

    attr_accessor :environment_variables
    attr_reader :executable, :args, :job_table

    # Returns a new Command or an instance of one of the classes in Builtins.
    def self.create(executable, job_table)
      Builtin.command_for(executable, job_table) || OSProcess.new(executable, job_table)
    end

    def initialize(executable, job_table = nil)
      @executable = executable
      @args = []
      @redirects = []
      @environment_variables = {}
      @status = nil
      @job_table = job_table
    end

    def shell
      job_table.shell
    end

    def complete(word)
      constant = @executable.capitalize
      if constant && (Completion.constants & [ constant, constant.to_sym ]).any?
        extend Completion.const_get(constant.to_sym)
        complete(word)
      else
        false
      end
    end

    def <<(argument)
      @args << argument
      self
    end

    def set_local_environment_variables
      @environment_variables.each_pair do |variable, value|
        ENV[variable] = value
      end
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

    def to_str
      "#{@executable} #{@args.join(" ")}"
    end
  end
end
