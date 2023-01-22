# Copyright (c) 2023 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Builtins
    class Exec < Builtin

      EXECUTABLE = "exec"

      def execute
        if @args.size == 0
          raise UrchinRuntimeError.new("No argument passed to exec.")
        end
        exec *@args
      end
    end
  end
end
