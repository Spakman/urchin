module Urchin
  def eval_config_file(urchin_rb)
    if File.exists?(urchin_rb) && File.readable?(urchin_rb)
      begin
        Urchin.module_eval File.read(urchin_rb)
      rescue Exception => exception
        STDERR.puts "Exception in #{urchin_rb}:"
        STDERR.puts exception.message
        STDERR.puts exception.backtrace.join("\n")
        STDERR.puts
      end
    end
  end

  module_function :eval_config_file
end
