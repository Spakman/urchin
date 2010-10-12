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
      @jobs = {}
      @index = 1
    end

    def insert(job)
      @jobs[@index] = job
      @index += 1
    end

    def delete(job)
      @jobs.delete_if { |id, j| j == job }
    end

    def to_s
      @jobs.map { |id, j| "[#{id}] #{j.status}     #{j.title}" }.join("\n")
    end

    def last_job
      job = nil
      index = 0
      @jobs.each do |id, j|
        if id > index
          job = j
        end
      end
      job
    end
  end
end
