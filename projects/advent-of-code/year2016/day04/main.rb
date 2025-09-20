include Enumerable

input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def parse_input(input)
  input.map do |line|
    a, b = line.split("[")
    checksum = b[..-2].chars
    c = a.split("-")
    sector_id = c.last.to_i
    chars = c[..-2].join("").chars
    { chars:, sector_id:, checksum:, name: c[..-2].join(" ") }
  end
end

def one(input)
  i = parse_input(input)

  i.sum do |i|
    chars = i[:chars].group_by { _1 }.transform_values { _1.size }.to_a.sort { |(l1, c1), (l2, c2)|
      if c1 == c2
        l1.ord - l2.ord
      else
        c2 - c1
      end
    }.map { _1.first }[0..4]

    if chars.all? { i[:checksum].include?(_1) }
      i[:sector_id]
    else
      0
    end
  end
end

def rot_str(str)
  str.split("").map {
    i = _1.ord + 1
    if i == ("z".ord + 1)
      "a"
    else
      i.chr
    end
  }.join("")
end

def two(input)
  i = parse_input(input)

  i.each do |i|
      val = i[:name]
      i[:sector_id].times do
        val = rot_str(val)
      end

      if val.include?("north")
        pp i[:sector_id]
      end
  end

  nil
end

puts "test:"
puts one(test_input)
# puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
