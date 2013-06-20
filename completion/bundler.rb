module Urchin
  module Completion
    module Bundle

      class << self
        def commands
          %w( check
              clean
              config
              console
              exec
              gem
              help
              init
              install
              open
              outdated
              package
              platform
              show
              update
              viz
            )
        end
      end

      def complete(word)
        if @args.empty? || (@args.size == 1 && !word.empty?)
          Bundle.commands.grep(/^#{Regexp.escape(word)}/)
        elsif @args.first == "exec"
          @args.delete_at(0)
          Readline.completion_proc.call(word, @args.join(" "))
        end
      end

    end
  end
end
