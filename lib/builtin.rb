# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/urchin_runtime_error"

module Urchin
  module Builtins
    module Methods
      def initialize(job_table)
        @args = []
        @job_table = job_table
      end

      def <<(arg)
        @args << arg
        self
      end
    end
  end
end
