# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Builtins
    module Methods
      def initialize(job_table)
        @args = []
        @job_table = job_table
      end

      # Just to keep things working.
      def environment_variables=(varaibles); end

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
