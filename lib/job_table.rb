# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  # Stores the list of running and suspended jobs along with job IDs.
  #
  # TODO: create smarter IDs.
  class JobTable
    attr_reader :jobs

    def initialize
      @jobs = []
      @index = 1
    end

    def insert(job)
      job.id = get_job_id
      @jobs << job
    end

    def get_job_id
      if @jobs.empty?
        1
      else
        @jobs.last.id + 1
      end
    end

    def delete(job)
      @jobs.delete job
    end

    def to_s
      @jobs.map { |job| "[#{job.id}] #{job.status}     #{job.title}" }.join("\n")
    end
  end
end
