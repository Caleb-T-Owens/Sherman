input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

def one(input)
  input.scan(/mul\([0-9]+,[0-9]+\)/).sum { 
    a, b = _1.split("(")[1].split(")")[0].split(",").map(&:to_i)
    a * b
  }
end

def two(input)
  
  input.size
  doing = true
  
  input.scan(/((mul\([0-9]+,[0-9]+\))|(do\(\))|(don\'t\(\)))/).sum { 
    if _1[0] == "do()"
      doing = true
      next 0
    elsif _1[0] == "don't()"
      doing = false
      next 0
    end
    next 0 unless doing
    a, b = _1[0].split("(")[1].split(")")[0].split(",").map(&:to_i)
    a * b
  }
end

puts "test:"
puts one(test_input)
puts two("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))")
puts "input:"
puts one(input)
puts two(input)