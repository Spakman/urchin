# Copyright (c) 2011 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class OSProcess < Command
    public_class_method :new
    attr_accessor :pid
    attr_reader :exit_code

    def add_redirect(from, to, mode)
      @redirects << { :from => from, :to => to, :mode => mode }
    end

    def perform_redirects
      @redirects.each do |redirect|
        if redirect[:to].respond_to? :reopen
          redirect[:from].reopen(redirect[:to])
        else
          redirect[:from].reopen(File.expand_path(redirect[:to]), redirect[:mode])
        end
      end
    end

    def execute
      perform_redirects
      set_local_environment_variables
      begin
        # Errno::EACCES can be thrown for many errors, so we detect directories
        # before calling exec().
        if /^(\.|\/)/ =~ @executable && File.directory?(@executable)
          abort "Is a directory: #{@executable}"
        end
        exec @executable, *@args

      rescue Errno::ENOENT
        abort "Command not found: #{@executable}"

      rescue Errno::EACCES
        abort "Permission denied: #{@executable}"
      end
    end

    # TODO: set exit code for when the status is #coredump? and #signaled?.
    def change_status(status)
      if status.stopped?
        stopped!
      else
        completed!
        if status.exited?
          @exit_code = status.exitstatus
        end
      end
    end

    def should_fork?
      true
    end
  end
end
