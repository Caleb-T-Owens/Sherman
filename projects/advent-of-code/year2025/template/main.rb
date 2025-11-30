require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  input.size
end

def two(input)
  input.size
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
