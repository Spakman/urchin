# Copyright (c) 2010-2012 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "ostruct"

module Urchin
  class History

    @before_appending_proc = nil

    class << self
      attr_reader :before_appending_proc
    end

    def initialize
      @entries = []
      @file = File.open(FILE, "a+")
      @file.sync = true
      @file.close_on_exec = true
      read_history
    end

    def self.before_appending(&block)
      @before_appending_proc = block
    end

    def cleanup
      @file.close unless @file.closed?
      Readline::HISTORY.to_a.size.times do
        Readline::HISTORY.pop
      end
    end

    def read_history
      contents = @file.read
      unless contents.empty?
        Marshal.load(contents).each do |line|
          @entries << line
          Readline::HISTORY.push line.input
        end
      end
    end

    # Appends the input to the Readline history (if it was not a duplicate of
    # the previous line) and writes it to the history file.
    #
    # TODO: use /dev/shm or some other method to save constant flushing.
    def append(history_line)
      unless history_line.input.empty? || Readline::HISTORY.to_a.last == history_line.input

        if History.before_appending_proc
          History.before_appending_proc.call(history_line)
        end

        Readline::HISTORY.push(history_line.input)

        @entries << history_line
        if @entries.size > LINES_TO_STORE
          @entries.slice!(0, @entries.size-LINES_TO_STORE)
        end

        difference = Readline::HISTORY.size - LINES_TO_STORE
        if difference > 0
          difference.times do
            Readline::HISTORY.shift
          end
        end

        @file.truncate(0)
        @file.write Marshal.dump(@entries)
      end
    end
  end
end
