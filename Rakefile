require 'rake/testtask'
require 'rubygems/package_task'

task :default => :test

Rake::TestTask.new do |t|
  t.warning = true
  t.verbose = true
  t.test_files = FileList["test/**/*_test.rb"]
  t.ruby_opts << "-Itest"
  t.ruby_opts << "-w"
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

desc "Build the gem"
task :build do
  system "gem build urchin.gemspec"
end
