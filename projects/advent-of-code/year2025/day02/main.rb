require "../lib/main.rb"
require "enumerator"

input = input_file("aoc-input.txt")
test_input = input_file("aoc-test.txt")

def one(input)
  ranges = input.split(",").map { a, b = _1.split("-").map(&:to_i); a..b }
  dups = []
  ranges.each do |r|
    r.each do |i|
      s = i.to_s.chars

      if s.size < 2
        next
      end

      parts = s.each_slice(s.size / 2).to_a;
      if parts.size == 2 && parts[1..].all? { _1 == parts[0] }
        dups << i
      end
    end
  end

  dups.sum
end

def two(input)
  ranges = input.split(",").map { a, b = _1.split("-").map(&:to_i); a..b }
  dups = []
  ranges.each do |r|
    r.each do |i|
      s = i.to_s.chars

      if s.size < 2
        next
      end

      (1..(s.size / 2)).each do |size|
        parts = s.each_slice(size).to_a;
        if parts.size > 1 && parts[1..].all? { _1 == parts[0] }
          dups << i
        end
      end
    end
  end

  dups.uniq.sum
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
