#!/usr/bin/ruby
# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "optparse"
require "#{File.dirname(__FILE__)}/lib/shell"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: rsh [options]"

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.on("-c", "--commands [COMMANDS]", "Run this command string, then exit") do |command_string|
    options[:command_string] = command_string
  end
end.parse!

if options[:command_string]
  RSH::Shell.new.run(options[:command_string])
else
  RSH::Shell.new.run_interactively
end
