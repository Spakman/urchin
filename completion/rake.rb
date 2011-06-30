module Urchin
  module Completion
    class Rake

      # Complicated Rakefiles (like Rails) can take a long time to parse, so
      # we cache the last result. 
      @@last_dir = @@last_tasks = nil

      # Complete task names.
      def complete(command, word)
        pwd = Dir.getwd
        unless @@last_dir == pwd
          @@last_dir = pwd
          @@last_tasks = tasks
        end
        return @@last_tasks.grep(/^#{Regexp.escape(word)}/)
      end

      def tasks
        lines = Shell.new.eval("rake -T").split("\n")[1..-1] || []
        lines.map { |l| l.sub(/^rake (.+?) .*$/, '\1') }
      end
    end
  end
end