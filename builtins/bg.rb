# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/../lib/builtin"
require "#{File.dirname(__FILE__)}/../lib/job_table"

module Urchin
  module Builtins
    class Bg
      include Methods

      def valid_arguments?
        if @args.size == 1
          if @args.first =~ /^%(\d+)$/
            @job_id = $1.to_i
          else
            raise UrchinRuntimeError.new("Argument doesn't look right.")
          end
        elsif @args.size > 1
          raise UrchinRuntimeError.new("Too many arguments.")
        end
      end

      def execute
        valid_arguments?
        job = @job_id ? @job_table.find_by_id(@job_id) : @job_table.jobs.last
        if job
          job.background!
        else
          raise UrchinRuntimeError.new("No current job.")
        end
      end
    end
  end
end
