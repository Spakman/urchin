#!/usr/bin/ruby
require 'readline'

while line = Readline.readline('> ', true)
  next if line.empty?

  commands = line.split("|")

  if commands.size == 1
    pid = fork do
      exec commands.first
    end
    Process.waitpid pid
    next
  end

  pids = []
  pipes = []

  # Because we need to sometimes have created two pipes before forking a
  # process, we only loop commands.size-1 times.
  commands[0..commands.size-2].each_with_index do |command, index|
    pipes << IO.pipe

    # The first command doesn't have to worry about reopening STDIN or closing
    # any pipes it doesn't need.
    if index == 0
      pids << fork do
        pipes[index].first.close
        $stdout.reopen pipes[index].last
        exec command
      end
    else
      pids << fork do

        # This process only needs access to the two most recently created
        # pipes, we *must* close the others.
        if pipes.size > 2
          pipes[0,pipes.size-2].each do |pipe|
            pipe.map { |p| p.close }
          end
        end

        pipes[index-1].last.close
        $stdin.reopen pipes[index-1].first
        $stdout.reopen pipes[index].last
        exec command
      end
    end
  end

  # Now let's fork the final command.
  pids << fork do
    if pipes.size > 2
      pipes[0,pipes.size-1].each do |pipe|
        pipe.map { |p| p.close }
      end
    end

    pipes.last.last.close
    $stdin.reopen pipes.last.first
    exec commands.last
  end

  pids.each_with_index do |pid, index|
    Process.waitpid pids[index]
    pipes[index].last.close unless pipes[index].nil?
  end
end
