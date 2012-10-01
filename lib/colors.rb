# Copyright (c) 2012 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

module Urchin
  module Colors
    Reset = "\e[0m"
    Bold = "\e[1m"
    Faint = "\e[2m"
    Standout = "\e[3m"
    Underline = "\e[4m"
    Reverse = "\e[7m"

    Black = "\e[0;30m"
    Red = "\e[0;31m"
    Green = "\e[0;32m"
    Yellow = "\e[0;33m"
    Blue = "\e[0;34m"
    Magenta = "\e[0;35m"
    Cyan = "\e[0;36m"
    White = "\e[0;37m"

    IntenseBlack = "\e[1;30m"
    IntenseRed = "\e[1;31m"
    IntenseGreen = "\e[1;32m"
    IntenseYellow = "\e[1;33m"
    IntenseBlue = "\e[1;34m"
    IntenseMagenta = "\e[1;35m"
    IntenseCyan = "\e[1;36m"
    IntenseWhite = "\e[1;37m"

    BackgroundBlack = "\e[1;40m"
    BackgroundRed = "\e[1;41m"
    BackgroundGreen = "\e[1;42m"
    BackgroundYellow = "\e[1;43m"
    BackgroundBlue = "\e[1;44m"
    BackgroundMagenta = "\e[1;45m"
    BackgroundCyan = "\e[1;46m"
    BackgroundWhite = "\e[1;47m"

    BackgroundIntenseBlack = "\e[1;100m"
    BackgroundIntenseRed = "\e[1;101m"
    BackgroundIntenseGreen = "\e[1;102m"
    BackgroundIntenseYellow = "\e[1;103m"
    BackgroundIntenseBlue = "\e[1;104m"
    BackgroundIntenseMagenta = "\e[1;105m"
    BackgroundIntenseCyan = "\e[1;106m"
    BackgroundIntenseWhite = "\e[1;107m"
  end
end
