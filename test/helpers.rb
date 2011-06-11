require "test/unit"

# If we are not the controlling process, we won't be able to set the foreground
# process group unless we ignore or block SIGTTOU.
Signal.trap :TTOU, "IGNORE"

$LOAD_PATH << "#{File.expand_path(File.dirname(__FILE__))}/../"

require "readline"
require "strscan"

begin
  require "termios"
rescue LoadError
  require "rubygems"
  require "termios"
  STDERR.puts "Loaded Termios using Rubygems. This is discouraged in order to save memory. You may want to consider installing it in site_ruby instead."
end

require "lib/history"
require "lib/shell"
require "lib/parser"
require "lib/job_table"
require "lib/job"
require "lib/command"
require "lib/ruby_command"
require "lib/builtin"
require "lib/urchin_runtime_error"

Dir.glob("#{File.dirname(__FILE__)}/../builtins/*.rb").each do |path|
  require path
end

unless defined? Urchin::History::FILE
  Urchin::History::FILE = "#{File.dirname(__FILE__)}/.urchin.test.history"
end

unless defined? Urchin::Builtins::Cd::LAST_DIR
  Urchin::Builtins::Cd::LAST_DIR = File.expand_path("#{File.dirname(__FILE__)}/.urchin.last.cd")
end

module Urchin
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
      FileUtils.mkdir("/tmp/urchin.test_unit")
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
