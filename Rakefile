task :default => :test

desc "Run the tests"
task :test do
  test_files = Dir.glob("test/*_test.rb")
  exec "testrb #{test_files.join(" ")}"
end
