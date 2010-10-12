# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/../lib/builtin"

module Urchin
  module Builtins
    class Cd
      include Methods

      def valid_arguments?
        if @arguments.size > 1
          raise UrchinRuntimeError.new("Too many arguments.")
        elsif @arguments.empty?
          @arguments << ENV['HOME']
        end
      end

      def execute
        valid_arguments?
        begin
          Dir.chdir @arguments.first
        rescue Errno::EACCES
          raise UrchinRuntimeError.new("Permission denied.")
        end
      end
    end
  end
end