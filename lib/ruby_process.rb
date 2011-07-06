# Copyright (c) 2011 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "rbconfig"
module Urchin
  class RubyProcess < OSProcess
    RUBY_PATH = File.join(Config::CONFIG["bindir"],
                          Config::CONFIG["RUBY_INSTALL_NAME"] +
                          Config::CONFIG["EXEEXT"])

    def self.create(source)
      ruby = new RUBY_PATH
      ruby << "-e" << source
    end
  end
end
