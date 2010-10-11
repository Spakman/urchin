# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/../lib/builtin"
require "#{File.dirname(__FILE__)}/../lib/job_table"

module Urchin
  module Builtins
    class Jobs
      include Methods

      def valid_arguments?
        unless @arguments.empty?
          raise UrchinRuntimeError.new("Too many arguments.")
        end
      end

      def execute
        valid_arguments?
        output = JOB_TABLE.to_s
        unless output.empty?
          puts output
        end
      end
    end
  end
end
