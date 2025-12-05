require "../lib/main.rb"

input = input_file("aoc-input.txt")
test_input =  input_file("aoc-test.txt")

def one(input)
  ranges, ids = input.split("\n\n")
  ids = ids.lines.map(&:to_i)
  ranges = ranges.lines.map { a, b = _1.split("-").map(&:to_i); a..b }

  ids.count { |a| ranges.any? { |r| r.include?(a) } }
end

def two(input)
  ranges, _ids = input.split("\n\n")
  ranges = ranges.lines.map { a, b = _1.split("-").map(&:to_i); a..b }

  merged_ranges = []

  ranges.each do |r|
    overlaps = merged_ranges.select { _1.overlap?(r) }

    sum = r

    overlaps.each do |overlap|
      merged_ranges.delete(overlap)
      sum = ([overlap.min, sum.min].min)..([overlap.max, sum.max].max)
    end

    merged_ranges << sum
  end

  merged_ranges.sum(&:count)
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)