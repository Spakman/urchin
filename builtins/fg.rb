# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Builtins
    class Fg < Builtin

      EXECUTABLE = "fg"

      def valid_arguments?
        @job_id = nil
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
          job.foreground!
        else
          raise UrchinRuntimeError.new("No current job.")
        end
      end
    end
  end
end
