# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "dl/import"

module Terminal
  if defined? DL::Importer
    # Ruby 1.9
    extend DL::Importer
  else
    # Ruby 1.8
    extend DL::Importable
  end
  # TODO: this is Linux specific
  dlload "libc.so.6"

  extern "int tcsetpgrp(int, int)"
  extern "int tcgetpgrp(int)"
end
