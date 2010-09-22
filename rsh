#!/usr/bin/ruby
# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/lib/shell"

RSH::Shell.new.run
