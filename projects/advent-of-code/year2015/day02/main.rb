input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  input.sum do |a|
    sms = Float::INFINITY
    area = a.split("x").map(&:to_i).permutation(2).sum do
      side = _1 * _2
      sms = [sms, side].min
      side
    end

    area + sms
  end
end

def two(input)
  input.sum do |a|
    ns = a.split("x").map(&:to_i)
    (ns.min(2) * 2).sum + ns.reduce(1, :*)
  end
end

puts "test:"
puts "p1:"
puts one(test_input)
puts "p2:"
puts two(test_input)
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
