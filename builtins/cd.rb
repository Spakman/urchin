# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/../lib/builtin"

module Urchin
  module Builtins
    class Cd
      include Methods

      # TODO: error checking and other features.
      def execute
        Dir.chdir @arguments.first
      end
    end
  end
end
