# If we are not the controlling process, we won't be able to set the foreground
# process group unless we ignore or block SIGTTOU.
Signal.trap :TTOU, "IGNORE"

# TODO: require all builtins.
require "#{File.dirname(__FILE__)}/../builtins/cd"

module Urchin
  module TestHelpers
    def teardown
      FileUtils.rm_r("/tmp/urchin.test_unit", :force => true)
    end

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
  end
end
