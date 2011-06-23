module Urchin
  class Completer
    def initialize(env_path, shell)
      build_executables_list_from(env_path)
      @shell = shell
    end

    def build_executables_list_from(env_path)
      @executables = []
      env_path.split(":").uniq.each do |path|
        if File.directory?(path) && File.executable?(path)
          Dir.entries(path).each do |entry|
            exec_path = File.expand_path("#{path}/#{entry}")
            if File.file?(exec_path) && File.executable?(exec_path)
              @executables << entry unless @executables.include? entry
            end
          end
        else
          STDERR.puts "#{path} is not a directory or is not executable."
        end
      end
    end

    def completion_proc
      Proc.new do |word|
        last_command = Parser.new(@shell).jobs_from(Readline.line_buffer).last.commands.last
        constant = last_command.executable.capitalize

        if(Completion.constants & [ constant, constant.to_sym ]).any?
          Completion.const_get(constant.to_sym).complete(last_command, word)
        else
          line = Readline.line_buffer.lstrip
          if word.empty? && !line.empty?
            Readline::FILENAME_COMPLETION_PROC.call(word)
          elsif line[0,1] != "." && line[0,1] != "/" && line[0,1] != "~" && line.index(word) == 0
            complete_executable(word)
          else
            Readline::FILENAME_COMPLETION_PROC.call(word)
          end
        end
      end
    end

    def complete_executable(word)
      @executables.grep(/^#{Regexp.escape(word)}/)
    end
  end
end
