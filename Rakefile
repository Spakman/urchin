task :default => :test

desc "Run the tests"
task :test do
  test_files = Dir.glob("test/**/*_test.rb")
  exec "testrb #{test_files.join(" ")}"
end

desc "Print out the TODO tasks"
task :todo do
  files = Dir.glob("**/*.rb") + [ "urchin" ]
  files.each do |filepath|
    if File.read(filepath) =~ /^\W*# TODO: (.*)$/
      puts "#{filepath}: #{$1}"
    end
  end
end
