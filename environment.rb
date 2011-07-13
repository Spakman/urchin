# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

# Set up the runtime environment.

if File.writable? "/dev/shm/"
  Urchin::TMP_DIR = "/dev/shm/urchin"
else
  Urchin::TMP_DIR = "/tmp/.urchin"
end
FileUtils.mkdir Urchin::TMP_DIR unless File.directory? Urchin::TMP_DIR


# Start in the last changed to directory.
Urchin::Builtins::Cd::LAST_DIR = "#{Urchin::TMP_DIR}/lastdir"

if File.readable? Urchin::Builtins::Cd::LAST_DIR
  last_dir = File.read(Urchin::Builtins::Cd::LAST_DIR).chomp
  unless last_dir.empty?
    begin
      Dir.chdir last_dir
    rescue
    end
  end
end


# Run any user defined configuration stuff.
Urchin::URCHIN_RB = "#{ENV["HOME"]}/.urchin.rb"

if File.exists?(Urchin::URCHIN_RB) && File.readable?(Urchin::URCHIN_RB)
  begin
    Urchin.module_eval File.read(Urchin::URCHIN_RB)
  rescue Exception => exception
    STDERR.puts "Exception in #{Urchin::URCHIN_RB}:"
    STDERR.puts exception.message
    STDERR.puts exception.backtrace.join("\n")
    STDERR.puts
  end
end


unless defined? Urchin::History::FILE
  Urchin::History::FILE = "#{ENV["HOME"]}/.urchin.history"
end

unless defined? Urchin::History::LINES_TO_STORE
  Urchin::History::LINES_TO_STORE = 1000
end
