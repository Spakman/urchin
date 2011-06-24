task :default => :test

desc "Run the tests"
task :test do
  test_files = Dir.glob("test/**/*_test.rb")
  exec "RUBYOPT='-w' testrb #{test_files.join(" ")}"
end

desc "Print out the TODO tasks"
task :todo do
  files = Dir.glob("**/*.rb") + [ "urchin" ]
  files.each do |filepath|
    File.readlines(filepath).each do |line|
      puts "#{filepath}: #{$1}" if line =~ /^ *# TODO: (.*)$/
    end
  end
end
