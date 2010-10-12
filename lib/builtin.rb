# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/urchin_runtime_error"

module Urchin
  module Builtins
    module Methods
      def initialize(job_table)
        @arguments = []
        @job_table = job_table
      end

      def append_arguments(args)
        @arguments += args
      end
    end
  end
end
