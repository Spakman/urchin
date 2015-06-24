unless defined? RbReadline
  STDERR.puts "rb-readline was not loaded. Bugs are fixed when using rb-readline instead of GNU Readline. In the future rb-readline will be required."
end

Readline.completer_quote_characters = "\\'\""
Readline.filename_quote_characters = " "

module RbReadline
  module_function :rl_point

  @rl_filename_dequoting_function = :filename_dequoting_function
  @rl_filename_quoting_function = :filename_quoting_function
  @rl_char_is_quoted_p = :char_is_quoted?
  @rl_completion_display_matches_hook = :display_hightlighted_matches

  def self.char_is_quoted?(buffer, point)
    buffer[point-1,1] == "\\" || buffer[point,1] == "\\"
  end

  def self.filename_quoting_function(filename, mtype, quote_char)
    return filename unless quote_char == 0.chr

    quoted_filename = filename.dup
    @rl_filename_quote_characters.each_char do |c|
      quoted_filename.gsub!(c, "\\#{c}")
    end
    quoted_filename
  end

  def self.filename_dequoting_function(filename, quote_char)
    quote_char = "\\" if quote_char == 0.chr
    filename.delete quote_char
  end

  # This overrides the RbReadline method by setting the
  # @current_completion_word so it can be used later.
  def self.display_hightlighted_matches(matches, len, max)
    @current_completion_word = matches.first

    # If there are many items, then ask the user if she really wants to
    #   see them all.
    if (@rl_completion_query_items > 0 && len >= @rl_completion_query_items)

      rl_crlf()
      @rl_outstream.write("Display all #{len} possibilities? (y or n)")
      @rl_outstream.flush
      if (get_y_or_n(false)==0)
        rl_crlf()

        rl_forced_update_display()
        @rl_display_fixed = true

        return
      end
    end

    rl_display_match_list(matches, len, max)

    rl_forced_update_display()
    @rl_display_fixed = true
  end

  class << self
    remove_method :fnprint
  end

  # This overrides the RbReadline method by displaying the
  # @current_completion_word and the next letters in the words in color.
  def self.fnprint(to_print)

    printed_len = 0

    case @encoding
    when 'E'
      arr = to_print.scan(/./me)
    when 'S'
      arr = to_print.scan(/./ms)
    when 'U'
      arr = to_print.scan(/./mu)
    when 'X'
      arr = to_print.dup.force_encoding(@encoding_name).chars
    else
      arr = to_print.scan(/./m)
    end

    output = ""

    arr.each do |s|
      if(ctrl_char(s))
        output << ('^'+(s[0].ord|0x40).chr.upcase)
        printed_len += 2
      elsif s == RUBOUT
        output << '^?'
        printed_len += 2
      else
        output << s
        if @encoding=='U'
          printed_len += s.unpack('U').first >= 0x1000 ? 2 : 1
        elsif @encoding=='X'
          printed_len += s.ord >= 0x1000 ? 2 : 1
        else
          printed_len += s.length
        end
      end

    end

    if @current_completion_word[-1] == "/"
      current_word = @current_completion_word
    else
      current_word = File.basename(@current_completion_word)
    end
    if current_word != ""
      @rl_outstream.write Urchin::Shell.completion_highlight_color
      unless output.sub!(/#{current_word}(.)?/, current_word + Urchin::Shell.completion_next_character_color + '\1' + "\e[0m")
        @rl_outstream.write Urchin::Colors::Reset
      end
    end
    @rl_outstream.write(output)

    printed_len
  end
end
