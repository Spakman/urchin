# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/../lib/builtin"

module Urchin
  module Builtins
    class Cd
      include Methods

      def initialize(executable)
        @@last_dir ||= nil
        super
      end

      def valid_arguments?
        if @args.size > 1
          raise UrchinRuntimeError.new("Too many arguments.")
        elsif @args.empty?
          @args << ENV['HOME']
        end
      end

      def execute
        valid_arguments?
        begin
          if @args.first == "-"
            if @@last_dir
              @args[0] = @@last_dir
            else
              raise UrchinRuntimeError.new("There is no previous directory.")
            end
          end
          if !File.directory? @args.first
            raise UrchinRuntimeError.new("Not a directory.")
          end
          @@last_dir = Dir.getwd
          Dir.chdir @args.first

          # Write the directory to URCHIN_LAST_CD so new shells know where to
          # start.
          File.open(URCHIN_LAST_CD, "w") do |file|
            file << "#{Dir.getwd}\n"
          end
        rescue Errno::EACCES
          raise UrchinRuntimeError.new("Permission denied.")
        end
      end
    end
  end
end
