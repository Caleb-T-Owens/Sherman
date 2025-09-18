input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  input.map { _1.split("") }.transpose.map { _1.group_by { |a| a }.transform_values { |a| a.size }.to_a.max { |(_, a1), (_, a2)| a1 <=> a2 }.first }.join("")
end

def two(input)
  input.map { _1.split("") }.transpose.map { _1.group_by { |a| a }.transform_values { |a| a.size }.to_a.max { |(_, a1), (_, a2)| a2 <=> a1 }.first }.join("")
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
