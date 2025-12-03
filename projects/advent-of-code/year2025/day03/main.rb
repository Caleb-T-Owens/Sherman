require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  input.sum do |line|
    ns = line.chars.map(&:to_i)
    max = ns[..-2].max
    max_i = ns.index(max)
    max2 = ns[(max_i+1)..].max
    "#{max}#{max2}".to_i
  end
end

def two(input)
  input.sum do |line|
    ns = line.chars.map(&:to_i)
    founds = []

    i = 0
    while founds.size < 12
      spare_room = ns.size - i + founds.size - 12
      set = ns[(i)..(i + spare_room)] || []
      max = set.max
      founds << max
      i += set.index(max) + 1
    end

    founds.join("").to_i
  end
end

puts "test:"
# puts one(test_input)
puts two(test_input)
# puts "input:"
# puts one(input)
puts two(input)