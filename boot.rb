require "optparse"
require "strscan"
require "fileutils"

require "rbconfig"
unless File.exists? "#{RbConfig::CONFIG["sitelibdir"]}/readline.rb"
  # Looks like rb-readline was not installed in site_ruby.
  require "rubygems"
end
begin
  require "rb-readline"
rescue LoadError
  require "rubygems"
  require "readline"
end

begin
  require "termios"
rescue LoadError
  # Looks like termios was not installed in site_ruby or we loaded the Gem
  # instead.
  require "rubygems"
  require "termios"
end

this_directory = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << this_directory
require "lib/colors"
require "lib/string"
require "lib/readline"
require "lib/completer"
require "lib/history"
require "lib/shell"
require "lib/parser"
require "lib/job_table"
require "lib/job"
require "lib/command"
require "lib/os_process"
require "lib/ruby_process"
require "lib/builtin"
require "lib/urchin_runtime_error"

Dir.glob("#{this_directory}/{builtins,completion}/*.rb").each do |path|
  require path
end

require "version"
require "environment"
