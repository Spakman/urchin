# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  class Command
    private_class_method :new

    attr_accessor :pid, :environment_variables
    attr_reader :exit_code

    def initialize(executable)
      @executable = executable
      @args = []
      @redirects = []
      @environment_variables = {}
    end

    # Returns a new Command or an instance of one of the classes in Builtins.
    def self.create(executable, job_table)
      constant = executable.capitalize
      if(Builtins.constants & [ constant, constant.to_sym ]).empty?
        new executable
      else
        Builtins.const_get(constant.to_sym).new(job_table)
      end
    end

    def <<(argument)
      @args << argument
      self
    end

    def add_redirect(from, to, mode)
      @redirects << { :from => from, :to => to, :mode => mode }
    end

    def perform_redirects
      @redirects.each do |redirect|
        if redirect[:to].respond_to? :reopen
          redirect[:from].reopen(redirect[:to])
        else
          redirect[:from].reopen(redirect[:to], redirect[:mode])
        end
      end
    end

    def execute
      perform_redirects
      set_local_environment_variables
      begin
        exec @executable, *@args
      rescue Errno::ENOENT
        STDERR.puts "Command not found: #{@executable}"
        exit 127
      end
    end

    def set_local_environment_variables
      @environment_variables.each_pair do |variable, value|
        ENV[variable] = value
      end
    end

    # Of course, we can't simply set the exit code from Command#execute because
    # that is only ever called after a fork. Instead, the Job will collect the
    # exit status from the child process and set it from there.
    def exit_code=(code)
      completed!
      @exit_code = code
    end

    def running!
      @status = :running
    end

    def stopped!
      @status = :stopped
    end

    def completed!
      @status = :completed
    end

    def running?
      @status == :running
    end

    def stopped?
      @status == :stopped
    end

    def completed?
      @status == :completed
    end

    def to_s
      "#{@executable} #{@args.join(" ")}"
    end

    def should_fork?
      true
    end
  end
end
