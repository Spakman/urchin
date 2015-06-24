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

Urchin::URCHIN_RB = "#{ENV["HOME"]}/.urchin.rb"

unless defined? Urchin::History::FILE
  Urchin::History::FILE = "#{ENV["HOME"]}/.urchin.history"
end

unless defined? Urchin::History::LINES_TO_STORE
  Urchin::History::LINES_TO_STORE = 1000
end


ENV["URCHIN_PID"] = Process.pid.to_s
