require "enumerator"
require "set"

input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

def parse_input(input)
  rs, is = input.split("\n\n")
  rs = rs.lines.map do
    a, b = _1.split(": ")
    [a, b.to_i]
  end.to_h

  is = is.lines.map do
    lhs, op, rhs, _a, out = _1.split(" ")
    { lhs:, op:, rhs:, out: }
  end

  loop do
    set = Set.new
    os = []
    is.each do
      _1 in { lhs:, op:, rhs:, out: }
      if set.include?(lhs) || set.include?(rhs)
        os.unshift({ lhs:, op:, rhs:, out: })
      else
        os.push({ lhs:, op:, rhs:, out: })
      end
      set << out
    end
    break if os == is
    is = os
  end

  return rs, is.reverse
end

def one(input)
  rs, is = parse_input(input)
  is.each do |i|
    case i[:op]
    when "XOR"
      rs[i[:out]] = (rs[i[:lhs]] || 0) ^ (rs[i[:rhs]] || 0)
    when "OR"
      rs[i[:out]] = (rs[i[:lhs]] || 0) | (rs[i[:rhs]] || 0)
    when "AND"
      rs[i[:out]] = (rs[i[:lhs]] || 0) & (rs[i[:rhs]] || 0)
    end
  end

  rs.select { |k, v| k.start_with? "z" }.sort_by { _1 }.map { |k, v| v.to_s }.join("").reverse.to_i(2)
end

OPS = {
  "XOR" => "x",
  "OR" => "o",
  "AND" => ">"
}

def two(input)
  if ENV["DEBUG_PRINT"] == "1"
    rs, is = parse_input(input)

    a = rs.select { |k, v| k.start_with? "x" }.sort_by { _1 }.map { |k, v| v.to_s }.join("").to_i(2)
    b =  rs.select { |k, v| k.start_with? "y" }.sort_by { _1 }.map { |k, v| v.to_s }.join("").to_i(2)
    puts (a + b).to_s(2)

    # Bung this into mermaid. Good luck :D
    is.each do |i|
      puts "    #{i[:lhs]} --#{OPS[i[:op]]} #{i[:out]}"
      puts "    #{i[:rhs]} --#{OPS[i[:op]]} #{i[:out]}"
      case i[:op]
      when "XOR"
        rs[i[:out]] = (rs[i[:lhs]] || 0) ^ (rs[i[:rhs]] || 0)
      when "OR"
        rs[i[:out]] = (rs[i[:lhs]] || 0) | (rs[i[:rhs]] || 0)
      when "AND"
        rs[i[:out]] = (rs[i[:lhs]] || 0) & (rs[i[:rhs]] || 0)
      end
    end

    rs.select { |k, v| k.start_with? "z" }.sort_by { _1 }.map { |k, v| v.to_s }.join("").reverse
  else
    "Not automated, run DEBUG_PRINT for mermaid"
  end
end

puts "test:"
puts "p1:"
puts one(test_input)
puts "p2:"
puts two("x00: 0
x01: 1
x02: 0
x03: 1
x04: 0
x05: 1
y00: 0
y01: 0
y02: 1
y03: 1
y04: 0
y05: 1

x00 AND y00 -> z05
x01 AND y01 -> z02
x02 AND y02 -> z01
x03 AND y03 -> z03
x04 AND y04 -> z04
x05 AND y05 -> z00")
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
