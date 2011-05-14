if defined? RbReadline
  RbReadline.rl_completer_quote_characters = "\\"
  RbReadline.rl_filename_quote_characters = " "
else
  STDERR.puts "rb-readline was not loaded. Bugs are fixed when using rb-readline instead of GNU Readline. In the future rb-readline will be required."
end

module RbReadline
  @rl_filename_dequoting_function = :filename_dequoting_function
  @rl_filename_quoting_function = :filename_quoting_function
  @rl_char_is_quoted_p = :char_is_quoted?

  def self.char_is_quoted?(buffer, point)
    buffer[point-1,1] == "\\" || buffer[point,1] == "\\"
  end

  def self.filename_quoting_function(filename, mtype, quote_char)
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
end
