module Urchin
  module Completion
    class Git

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
      )

      def complete(command, word)
        if command.args.empty? || (command.args.size == 1 && !word.empty?)
          Git.commands.grep(/^#{Regexp.escape(word)}/)
        elsif command.args.size >= 1
          send(command.args.first.to_sym, command.args[1..-1], word)
        end
      end

      def method_missing(name, *args)
        Readline::FILENAME_COMPLETION_PROC.call(args.last)
      end

      def checkout(args, word)
        if (args & %w( -b -B )).empty?
          branches = local_branches
          if (branches & args).empty?
            branches.grep(/^#{Regexp.escape(word)}/)
          else
            Readline::FILENAME_COMPLETION_PROC.call(args.last)
          end
        else
          []
        end 
      end

      def branch(args, word)
        if args.include? "-D"
          local_branches.grep(/^#{Regexp.escape(word)}/)
        else
          []
        end
      end

      def local_branches
        Shell.new.eval("git branch --no-color").gsub(/^[ *] /, "").split("\n")
      end
    end
  end
end
