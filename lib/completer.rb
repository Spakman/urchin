module Urchin
  class Completer
    def initialize(env_path)
      build_executables_list_from(env_path)
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
        line = Readline.line_buffer.lstrip
        if line[0,1] != "." && line[0,1] != "/" && line[0,1] != "~" && line.index(word) == 0
          complete_executable(word)
        else
          Readline::FILENAME_COMPLETION_PROC.call(word)
        end
      end
    end

    def complete_executable(word)
      @executables.grep(/^#{Regexp.escape(word)}/)
    end
  end
end
