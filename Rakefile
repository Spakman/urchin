# If we are not the controlling process, we won't be able to set the foreground
# process group unless we ignore or block SIGTTOU.
Signal.trap :TTOU, "IGNORE"

task :default => :test

desc "Run the tests"
task :test do
  test_files = Dir.glob("test/*_test.rb")
  system "testrb #{test_files.join(" ")}"
end
