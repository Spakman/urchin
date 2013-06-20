module Urchin
  module Completion
    module Gem

      class << self
        def commands
          %w(
              build
              cert
              check
              cleanup
              contents
              dependency
              environment
              fetch
              generate_index
              help
              install
              list
              lock
              mirror
              outdated
              owner
              pristine
              push
              query
              rdoc
              search
              server
              sources
              specification
              stale
              uninstall
              unpack
              update
              which
              yank
            )
        end
      end

      def complete(word)
        if @args.empty? || (@args.size == 1 && !word.empty?)
          Gem.commands.grep(/^#{Regexp.escape(word)}/)
        end
      end

    end
  end
end
