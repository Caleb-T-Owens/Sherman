require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  # Easy input?...
  c = 0
  input[30..].each do |l|
    sz, n = l.split(": ")
    space_available  = sz.split("x").map(&:to_i).reduce { _1 * _2 }
    x = n.split(" ").map(&:to_i).map { _1 * 8 }.sum
    if space_available > x
      c += 1
    end
  end

  c
end

puts "test:"
puts one(test_input)
puts "input:"
puts one(input)
