entries = File.readlines("aoc-input.txt", chomp: true).map { _1.split("   ").map(&:to_i) }.transpose.map(&:sort).transpose

puts entries.sum { |(a, b)| (a - b).abs }

a, b = entries.transpose

puts a.sum { |x| b.count { _1 == x } * x }
