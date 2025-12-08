require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input, con_c)
  points = input.map { _1.split(",").map(&:to_i) }
  circuts = points.map { [_1] }
  joins = points.combination(2).map do |a, b|
    score = ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5
    [a, b, score]
  end.min(con_c) { _1[2] <=> _2[2] }.map { _1[0..1] }

  joins.each do |(to, from)|
    tos = circuts.find { _1.include?(to) }
    froms = circuts.find { _1.include?(from) }

    next if tos == froms

    circuts.delete(tos)
    circuts.delete(froms)
    circuts.push([*tos, *froms].uniq)
  end

  circuts.map { _1.size }.max(3).reduce { _1 * _2 }
end

def two(input)
  points = input.map { _1.split(",").map(&:to_i) }
  circuts = points.map { [_1] }
  joins = points.combination(2).map do |a, b|
    score = ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5
    [a, b, score]
  end.sort_by { _1[2] }.map { _1[0..1] }

  score = 0

  joins.each do |(to, from)|
    tos = circuts.find { _1.include?(to) }
    froms = circuts.find { _1.include?(from) }

    next if tos == froms

    circuts.delete(tos)
    circuts.delete(froms)
    circuts.push([*tos, *froms].uniq)

    if circuts.size == 1
      score = to[0] * from[0]
      break
    end
  end

  score
end

puts "test:"
puts one(test_input, 10)
puts two(test_input)
puts "input:"
puts one(input, 1000)
puts two(input)
