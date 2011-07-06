# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Builtins

    # Loads the class instance variable @builtins with
    #
    #   "builtin_executable" => BuiltinClassName
    #
    # pairs if it is not defined (and then returns it).
    def self.builtins
      @builtins ||= {}
      if @builtins.empty?
        constants.each do |b|
          next if b == :Methods || b == "Methods"
          klass = const_get(b)
          @builtins[klass::EXECUTABLE] = klass
        end
      end
      @builtins
    end

    # Returns an instance of the Builtin class for a given executable or nil.
    def self.command_for(executable, job_table)
      if builtins[executable]
        builtins[executable].new(job_table)
      end
    end

    module Methods
      attr_reader :args

      def initialize(job_table)
        @args = []
        @job_table = job_table
      end

      # Just to keep things working.
      def environment_variables=(variables); end

      def executable
        self.class.to_s.downcase
      end

      # This is duplicated in the Command class.
      def complete
        constant = self.class.to_s
        if constant && (Completion.constants & [ constant, constant.to_sym ]).any?
          Completion.const_get(constant.to_sym).new.complete(self, @args.last || "")
        else
          false
        end
      end

      def <<(arg)
        @args << arg
        self
      end

      def should_fork?
        false
      end

      # This will only get called after execute has completed.
      def completed?
        true
      end

      # This will only get called after execute has completed.
      def running?
        false
      end
    end
  end
end
