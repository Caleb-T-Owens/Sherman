input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def mix(a, b)
  a ^ b
end

def prune(a)
  a % 16777216
end

def next_number(value)
  value = prune(mix(value * 64, value))
  value = prune(mix(value / 32, value))
  value = prune(mix(value * 2048, value))
end

def one(input)
  input.sum do |i|
    number = i.to_i
    2000.times do
      number = next_number(number)
    end
    number
  end
end

def two(input)
  map = []
  input.each do |i|
    mmap = {}
    number = i.to_i
    digits = [number % 10]
    2000.times do
      number = next_number(number)
      digits << number % 10
    end
    transitions = digits.each_cons(2).map { |(a, b)| a - b }
    transitions.each_cons(4).each_with_index do |pairs, index|
      mmap[pairs] ||= digits[index + 4]
    end
    map << mmap
  end

  largest = 0
  largest_key = nil

  keys = map.map { _1.keys }.flatten(1).uniq
  keys.each_with_index do |pairs, i|
    sum = map.sum do |vs|
      vs[pairs] || 0
    end
    if sum > largest
      largest_key = pairs
      largest = sum
    end
  end

  largest
end

puts "test:"
puts "p1:"
puts one(test_input)
puts "p2:"
puts two("1
2
3
2024".lines)
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
