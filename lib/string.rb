# Copyright (c) 2011 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

# Ruby 1.8.6 lacks String#each_char.
unless String.method_defined? :each_char
  class String
    def each_char
      self.split("").each do |char|
        yield char
      end
    end
  end
end
