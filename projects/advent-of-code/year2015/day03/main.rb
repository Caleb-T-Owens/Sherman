require "set"
require "matrix"

input = File.read("aoc-input.txt", chomp: true)

DIR = {
  "^" => Vector[-1, 0],
  "v" => Vector[+1, 0],
  "<" => Vector[0, -1],
  ">" => Vector[0, +1],
}

def add((ax, ay), (bx, by))
end

def one(input)
  current = Vector[0, 0]
  poses = Set[current]
  input.each_char do |char|
    current = current + DIR[char]
    poses << current
  end
  poses.size
end

def two(input)
  santa = Vector[0, 0]
  robo = Vector[0, 0]
  poses = Set[santa]
  input.each_char.each_with_index do |char, index|
    if index % 2 == 0
      robo = robo + DIR[char]
      poses << robo
    else
      santa = santa + DIR[char]
      poses << santa
    end
  end
  poses.size
end

puts "test:"
puts "p1.a:"
puts one(">")
puts "p1.b:"
puts one("^>v<")
puts "p1.c:"
puts one("^v^v^v^v^v")
puts "p2.a:"
puts two("^v")
puts "p2.b:"
puts two("^>v<")
puts "p2.c:"
puts two("^v^v^v^v^v")
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
