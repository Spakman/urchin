require "optparse"
require "strscan"
require "fileutils"

require "readline"
require "rb-readline"
require "termios"

this_directory = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << this_directory
require "lib/startup"
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
