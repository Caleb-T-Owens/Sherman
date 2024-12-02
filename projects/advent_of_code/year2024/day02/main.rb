input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  input.count { 
    as = _1.split(" ")
    as.each_cons(2).all? { |(a, b)| b.to_i > a.to_i &&  b.to_i - a.to_i >= 1 && b.to_i - a.to_i <= 3 } ||
    as.each_cons(2).all? { |(a, b)| a.to_i > b.to_i && a.to_i - b.to_i >= 1 && a.to_i - b.to_i <= 3 }
  }
end

def two(input)
  input.count { 
    as = _1.split(" ")
    list_with_one_missing(as).any? { |x|
      x.each_cons(2).all? { |(a, b)| b.to_i > a.to_i && b.to_i - a.to_i >= 1 && b.to_i - a.to_i <= 3 } ||
      x.each_cons(2).all? { |(a, b)| a.to_i > b.to_i && a.to_i - b.to_i >= 1 && a.to_i - b.to_i <= 3 }
    } 
  }
end

def list_with_one_missing(list)
  list.length.times.map { (_1 != 0 ? list[0..(_1 - 1)] : []) + ((_1 != list.length - 1) ? list[(_1 + 1)..list.length] : [])} + [list]
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
