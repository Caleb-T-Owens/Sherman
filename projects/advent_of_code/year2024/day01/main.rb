a, b = File.readlines("aoc-input.txt", chomp: true).map { _1.split("   ").map(&:to_i) }.transpose.map(&:sort)

puts [a, b].transpose.sum { |(a, b)| (a - b).abs }

puts a.sum { |x| b.count { _1 == x } * x }
