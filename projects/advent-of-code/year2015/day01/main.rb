input = File.read("aoc-input.txt", chomp: true)

def one(input)
  input.each_char.reduce(0) { |a, b| a + (b == "(" ? 1 : -1) }
end

def two(input)
  floor = 0
  input.each_char.each_with_index do |char, index|
    if char == "("
      floor += 1
    else
      floor -= 1
    end

    if floor < 0
      return index + 1
    end
  end
end

puts "test:"
puts "p2.a:"
puts two(")")
puts "p2.b:"
puts two("()())")
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
