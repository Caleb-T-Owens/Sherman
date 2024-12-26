require "enumerator"

input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

NAUGHTY = ["ab", "cd", "pq", "xy"]
VOWELS = ["a", "e", "i", "o", "u"]

def one(input)
  input.count do |line|
    next false if NAUGHTY.any? { line.include? _1 }
    next false if VOWELS.sum { line.count _1 } < 3
    if line.chars.each_cons(2).any? { |(a, b)| a == b }
      true
    else
      false
    end
  end
end

def two(input)
  input.count do |line|
    next false unless line.chars.each_cons(3).any? { |(a, _, b)| a == b }
    chunks = {}
    line = line
    until line.size <= 1
      chunks[line[0..1]] ||= 0
      chunks[line[0..1]] += 1
      if line[0] == line[1] && line[1] == line[2]
        line = line[2..]
      else
        line = line[1..]
      end
    end

    next false unless chunks.values.any? { _1 >= 2 }
    true
  end
end

puts "test:"
puts one(test_input)
puts two("qjhvhtzxzqqjkmpb
xxyxx
uurcxstgmygtbstg
ieodomkazucvgmuy".lines)
puts "input:"
puts one(input)
puts two(input)
