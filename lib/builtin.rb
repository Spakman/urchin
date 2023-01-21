# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class Builtin < Command
    public_class_method :new

    # This can be overridden in order to return an OSProcess instance, for
    # example. A tad unclean perhaps, but more straightforward for now than
    # implementing a new "functions" feature for user defined stuff.
    def self.build(job_table)
      self.new(job_table)
    end

    def initialize(job_table)
      @job_table = job_table
      super(self.class::EXECUTABLE, job_table)
    end

    def should_fork?
      false
    end

    def completed?
      true
    end

    # Loads the class instance variable @builtins with
    #
    #   "builtin_executable" => BuiltinClassName
    #
    # pairs if it is not defined (and then returns it).
    def self.builtins
      @builtins ||= {}
      if @builtins.empty?
        Builtins.constants.each do |b|
          klass = Builtins.const_get(b)
          @builtins[klass::EXECUTABLE] = klass
        end
      end
      @builtins
    end

    # Returns an instance of the Builtin class for a given executable or nil.
    def self.command_for(executable, job_table)
      if builtins[executable]
        builtins[executable].build(job_table)
      end
    end
  end
end
