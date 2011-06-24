# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Builtins
    class Jobs
      include Methods

      def valid_arguments?
        unless @args.empty?
          raise UrchinRuntimeError.new("Too many arguments.")
        end
      end

      def execute
        valid_arguments?
        output = @job_table.to_s
        unless output.empty?
          puts output
        end
      end
    end
  end
end
