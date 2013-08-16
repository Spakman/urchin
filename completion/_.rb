module Urchin
  module Completion
    module Underscore

      def complete(word)
        if @args.empty? || (@args.size == 1 && !word.empty?)
          commands.grep(/^#{Regexp.escape(word)}/)
        end
      end

    end
  end
end
