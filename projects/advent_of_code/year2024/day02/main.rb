input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  input.size
end

def two(input)
  input.size
end

puts "test:"
puts one(test_input)
puts one(test_input)
puts "input:"
puts one(input)
puts one(input)
