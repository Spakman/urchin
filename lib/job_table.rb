# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  # Stores the list of running and suspended jobs along with job IDs.
  class JobTable
    attr_reader :jobs, :shell

    def initialize(shell)
      @jobs = []
      @shell = shell
    end

    def insert(job)
      job.id = get_job_id
      @jobs << job
    end

    # Re-order the jobs in the job table.
    def last_job=(job)
      @jobs.delete job
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
      @jobs.sort.map { |j| "[#{j.id}] #{j.status}     #{j.title}" }.join("\n")
    end

    def find_by_id(id)
      @jobs.find { |j| j.id == id }
    end
  end
end
