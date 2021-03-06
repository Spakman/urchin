require "set"

module Urchin
  module Completion
    module Git

      class << self
        attr_reader :commands
      end

      @commands = %w( 
        add am archive annotate archimport
        bisect branch bundle blame
        checkout cherry-pick citool clean clone commit config cherry count-objects cvsexportcommit cvsimport cvsserver
        describe diff difftool
        fetch format-patch fast-export fast-import filter-branch fsck
        gc grep gui get-tar-commit-id
        help
        instaweb init imap-send
        log lost-found
        merge mv mergetool merge-tree
        notes
        pull push pack-refs prune
        quiltimport
        rebase reset revert request-pull reflog relink remote repack replace repo-config rerere rev-parse rm
        shortlog show stash status submodule show-branch send-email svn
        tag
        verify-tag
        whatchanged
      ).to_set

      # Sets up completion for any aliases that are defined. As well as adding
      # the alises to the command list, this defines methods to pass any calls
      # for sub-command specific completion to the command being alised.
      def self.extended(instance)
        instance.shell.eval("git config --get-regex alias").lines.each do |line|
          line.chomp!
          if line =~ /^alias\.(\w+?) (.+)$/
            instance.instance_eval <<-METH
              def #{$1}(args, word)
                send :"#{$2.split.first}", args, word
              end
            METH
            @commands << $1
          end
        end
      end

      def complete(word)
        if args.empty? || (args.size == 1 && !word.empty?)
          Git.commands.grep(/^#{Regexp.escape(word)}/)
        elsif args.size >= 1
          send(args.first.to_sym, args[1..-1], word)
        end
      end

      def method_missing(name, *args)
        complete_local_branches(args.last)
      end

      def branch(args, word)
        if args.include? "-D"
          complete_local_branches(word)
        else
          []
        end
      end

      def local_branches
        shell.eval("git branch --no-color").gsub(/^[ *] /, "").split("\n")
      end

      def complete_local_branches(word)
        branches = local_branches.grep(/^#{Regexp.escape(word)}/)
        if branches.any?
          branches
        else
          false
        end
      end
    end
  end
end
