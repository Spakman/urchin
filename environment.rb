# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

# Set up the runtime environment.

xdg_runtime_dir = Pathname.new(ENV["XDG_RUNTIME_DIR"] || "")
if File.writable? xdg_runtime_dir
  Urchin::TMP_DIR = xdg_runtime_dir + "urchin"
else
  Urchin::TMP_DIR = "/tmp/.urchin"
  STDERR.puts "XDG_RUNTIME_DIR is not writable - using #{Urchin::TMP_DIR} instead."
end
begin
  FileUtils.mkdir Urchin::TMP_DIR unless File.directory? Urchin::TMP_DIR
rescue Errno::EEXIST
end

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

xdg_config_home = Pathname.new(ENV["XDG_CONFIG_HOME"] || "#{ENV["HOME"]}/.config")
xdg_data_home = Pathname.new(ENV["XDG_DATA_HOME"] || "#{ENV["HOME"]}/.local/share")
urchin_config_dir = xdg_config_home + "urchin"
urchin_data_dir = xdg_data_home + "urchin"
FileUtils.mkdir_p(urchin_config_dir)
FileUtils.mkdir_p(urchin_data_dir)

Urchin::URCHIN_RB = urchin_config_dir + "urchin.rb"

unless defined? Urchin::History::FILE
  Urchin::History::FILE = urchin_data_dir + "urchin.history"
end

unless defined? Urchin::History::LINES_TO_STORE
  Urchin::History::LINES_TO_STORE = 1000
end


ENV["URCHIN_PID"] = Process.pid.to_s
