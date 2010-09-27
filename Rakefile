task :default => :test

desc "Run the tests"
task :test do
  test_files = Dir.glob("test/*_test.rb")
  test_file_args = test_files.map { |f| "-a #{f}" }
  exec "testrb -b test -w #{File.dirname(__FILE__)} #{test_file_args.join(" ")}"
end
