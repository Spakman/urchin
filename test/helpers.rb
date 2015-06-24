module Readline
end
require "rb-readline"

require "minitest"
require "minitest/autorun"

# If we are not the controlling process, we won't be able to set the foreground
# process group unless we ignore or block SIGTTOU.
Signal.trap :TTOU, "IGNORE"

require "#{File.dirname(__FILE__)}/../boot"

if defined? Urchin::History::FILE
  Urchin::History.send(:remove_const, :FILE)
end
Urchin::History::FILE = "#{File.dirname(__FILE__)}/.urchin.test.history"

if defined? Urchin::History::LINES_TO_STORE
  Urchin::History.send(:remove_const, :LINES_TO_STORE)
end
Urchin::History::LINES_TO_STORE = 3

if defined? Urchin::Builtins::Cd::LAST_DIR
  Urchin::Builtins::Cd.send(:remove_const, :LAST_DIR)
end
Urchin::Builtins::Cd::LAST_DIR = File.expand_path("#{File.dirname(__FILE__)}/.urchin.last.cd")

class Urchin::Shell
  @@aliases = {}

  def self.clear_aliases
    @@aliases = {}
  end
end

module Urchin

  # Override #initialize to make writing the tests a little neater.
  class JobTable
    alias_method :old_initialize, :initialize

    def initialize(shell = Shell.new)
      old_initialize(shell)
    end
  end

  module TestHelpers

    class JobForTest
      attr_accessor :foreground, :background, :id, :title
      def foreground!; @foreground = true; end
      def background!; @background = true; end
      def status; :running; end
    end

    def teardown
      FileUtils.rm_r("/tmp/urchin.test_unit", :force => true)
    end

    alias_method :old_teardown, :teardown

    def redirect_stdout
      FileUtils.mkdir_p("/tmp/urchin.test_unit")
      @old_stdout = STDOUT.dup
      @redirected_stdout = File.open("/tmp/urchin.test_unit/stdout", "w+")
      STDOUT.reopen @redirected_stdout
    end

    def reopen_stdout
      STDOUT.reopen @old_stdout
      @old_stdout.close
      @redirected_stdout.rewind
      output = @redirected_stdout.read
      @redirected_stdout.close
      return output
    end

    def with_redirected_output(&block)
      redirect_stdout
      begin
        yield
      rescue Exception => exception
        STDERR.puts exception.message
        STDERR.puts exception.backtrace.join("\n")
      end
      reopen_stdout
    end

    def cleanup_history
      @shell.history.cleanup
      FileUtils.rm_f History::FILE
    end
  end
end
