input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  map = {}
  input.each_with_index do |row, x|
    row.split("").each_with_index do |trail, y|
      map[[x, y]] = trail.to_i
    end
  end

  map.sum do |(x, y), trail|
    if trail == 0
      find_trail_heads(map, x, y).uniq.size
    else
      0
    end
  end
end

def find_trail_heads(input, x, y)
  current = input[[x, y]]
  if current == 9
    return [[x, y]]
  end

  out = []
  if input[[x + 1, y]] && input[[x + 1, y]] == current + 1
    out += find_trail_heads(input, x + 1, y)
  end
  if input[[x - 1, y]] && input[[x - 1, y]] == current + 1
    out += find_trail_heads(input, x - 1, y)
  end
  if input[[x, y + 1]] && input[[x, y + 1]] == current + 1
    out += find_trail_heads(input, x, y + 1)
  end
  if input[[x, y - 1]] && input[[x, y - 1]] == current + 1
    out += find_trail_heads(input, x, y - 1)
  end

  out
end

def two(input)
  map = {}
  input.each_with_index do |row, x|
    row.split("").each_with_index do |trail, y|
      map[[x, y]] = trail.to_i
    end
  end

  map.sum do |(x, y), trail|
    if trail == 0
      find_trail_heads(map, x, y).size
    else
      0
    end
  end
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
