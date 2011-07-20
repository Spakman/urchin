# This file is -r required when creating an external Ruby process.

alias :o :puts

def s
  STDIN.read
end

def a(sep = $/)
  STDIN.readlines(sep)
end

def i
  STDIN.read.to_i
end
