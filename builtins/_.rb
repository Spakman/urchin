# Copyright (c) 2013 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Builtins
    class Underscore < Builtin

      EXECUTABLE = "_"

      def valid_arguments?
        @args.each do |arg|
          unless respond_to? arg
            raise UrchinRuntimeError.new("#{arg} is not a valid argument.")
          end
        end
      end

      def execute
        valid_arguments?
        if args.any?
          send(args.first)
        else
          puts ENV["URCHIN_PID"]
        end
      end

      def commands
        %w( reload_config )
      end

      def reload_config
        Urchin.eval_config_file(URCHIN_RB)
      end
    end
  end
end
