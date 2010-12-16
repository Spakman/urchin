# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class History
    def initialize
      setup_history
    end

    def cleanup
      @file.close unless @file.closed?
      Readline::HISTORY.to_a.size.times do
        Readline::HISTORY.pop
      end
    end

    def setup_history
      if File.readable? URCHIN_HISTORY
        File.readlines(URCHIN_HISTORY).each do |line|
          Readline::HISTORY.push line.chomp
        end
      end
      @file = File.open(URCHIN_HISTORY, "a+")
      begin
        @file.close_on_exec = true
      rescue NoMethodError
      end
    end

    # Appends the input to the Readline history (if it was not a duplicate of
    # the previous line) and writes it to the history file.
    #
    # TODO: use /dev/shm or some other method to save constant flushing.
    #
    # TODO: limit the number of entries in the history file.
    def append(input)
      unless input.empty? || Readline::HISTORY.to_a.last == input
        Readline::HISTORY.push(input)

        # Some versions of libedit have a bug where the first item isn't added
        # to the history.
        Readline::HISTORY.push(input) if Readline::HISTORY.to_a.empty?

        @file << "#{input}\n"
        @file.flush
      end
    end
  end
end
