module Urchin
  module Colours

    def self.colour(colour_string, &block)
      output = colour_string
      output << yield
      output << reset
      return output
    end

    COLOURS = {
      :blue => "\e[0;34m",
      :cyan => "\e[0;36m",
      :green => "\e[1;32m",
      :red => "\e[1;31m",
      :reset => "\e[0m"
    }

    def self.method_missing(name, *args)
      if COLOURS[name]
        if block_given?
         #output = COLOURS[name]
          output = ""
          output << yield
         #output << COLOURS[:reset]
          return output
        else
          COLOURS[name]
        end
      end
    end
  end
end
