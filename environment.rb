# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

# Set up the runtime environment.

if File.writable? "/dev/shm/"
  URCHIN_TMP = "/dev/shm/urchin"
else
  URCHIN_TMP = "/tmp/.urchin"
end
FileUtils.mkdir URCHIN_TMP unless File.directory? URCHIN_TMP


# Start in the last changed to directory.
URCHIN_LAST_CD = "#{URCHIN_TMP}/lastdir"

if File.readable? URCHIN_LAST_CD
  last_dir = File.read(URCHIN_LAST_CD).chomp
  unless last_dir.empty?
    begin
      Dir.chdir last_dir
    rescue
    end
  end
end


# Run any user defined configuration stuff.
URCHIN_RB = "#{ENV["HOME"]}/.urchin.rb"

if File.exists?(URCHIN_RB) && File.readable?(URCHIN_RB)
  Urchin.module_eval File.read(URCHIN_RB)
end


unless defined? URCHIN_HISTORY
  URCHIN_HISTORY = "#{ENV["HOME"]}/.urchin.history"
end
