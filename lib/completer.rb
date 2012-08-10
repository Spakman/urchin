module Urchin
  class Completer
    def initialize(env_path, shell)
      @shell = shell
      build_executables_list_from(env_path)
    end

    def aliases
      @shell.aliases.keys
    end

    def builtins
      Builtin.builtins.keys
    end

    def build_executables_list_from(env_path)
      @executables = aliases | builtins
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
        parser = Parser.new(@shell)
        last_job = parser.jobs_from(Readline.line_buffer[0,Readline.point]).last

        if parser.start_of_new_command?
          complete_executable(word)
        elsif Readline.line_buffer[Readline.point-(word.length)-1,1] == "$"
          complete_environment_variable(word)
        else
          command = last_job.commands.last if last_job
          if !parser.finished_entering_alias?
            complete_executable(word)
          elsif command && (command.args.any? || Readline.line_buffer[Readline.point-1,1] == " ")
            command.complete(word) or Readline::FILENAME_COMPLETION_PROC.call(word)
          else
            complete_executable(word)
          end
        end
      end
    end

    def complete_executable(word)
      if %w( . / ~ ).include? word.lstrip[0,1]
        Readline::FILENAME_COMPLETION_PROC.call(word)
      else
        @executables.grep(/^#{Regexp.escape(word)}/)
      end
    end

    def complete_environment_variable(word)
      ENV.keys.grep(/^#{Regexp.escape(word)}/)
    end
  end
end
