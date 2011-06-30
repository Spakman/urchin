# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Builtins
    class Export

      EXECUTABLE = "export"

      include Methods

      def valid_arguments?
        if @args.empty?
          raise UrchinRuntimeError.new("Requires an argument.")
        elsif
          @args = @args.join(" ")
          unless @args =~ /^[A-Z0-9a-z_]+?=(?:[^ ].*|\s*)$/
            raise UrchinRuntimeError.new("Argument is malformed.")
          end
        end
      end

      # Variables are exported using the following syntax:
      #
      # VAR=123
      # VAR="this is a value"
      #
      # Unsetting a variable is accomplished using:
      #
      # VAR=
      def execute
        valid_arguments?

        variable, value = @args.split("=")

        parser = Urchin::Parser.new(nil, value || "")
        value = (parser.quoted_word or parser.word)

        if parser.quoted_word or parser.word
          raise UrchinRuntimeError.new("Too many arguments.")
        end

        ENV[variable.strip] = value
      end
    end
  end
end
