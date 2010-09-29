# If we are not the controlling process, we won't be able to set the foreground
# process group unless we ignore or block SIGTTOU.
Signal.trap :TTOU, "IGNORE"

module RSH
  module TestHelpers
    def teardown
      FileUtils.rm_r("/tmp/rsh.test_unit", :force => true)
    end

    def redirect_stdout
      FileUtils.mkdir("/tmp/rsh.test_unit")
      @old_stdout = STDOUT.dup
      @redirected_stdout = File.open("/tmp/rsh.test_unit/stdout", "w+")
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
      yield
      reopen_stdout
    end
  end
end
