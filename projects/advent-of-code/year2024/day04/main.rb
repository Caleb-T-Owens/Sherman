input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def get_directions(x, y, input)
  output = []
  if x < input.size - 3
    if y < input[0].size - 3
      output << [[x, y], [x + 1, y + 1], [x + 2, y + 2], [x + 3, y + 3]]
    end

      output << [[x, y], [x + 1, y], [x + 2, y], [x + 3, y]]

    if y > 2
      output << [[x, y], [x + 1, y - 1], [x + 2, y - 2], [x + 3, y - 3]]
    end
  end

  if x > 2
    if y < input[0].size - 3
      output << [[x, y], [x - 1, y + 1], [x - 2, y + 2], [x - 3, y + 3]]
    end

      output << [[x, y], [x - 1, y], [x - 2, y], [x - 3, y]]

    if y > 2
      output << [[x, y], [x - 1, y - 1], [x - 2, y - 2], [x - 3, y - 3]]
    end
  end

  if y > 2
      output << [[x, y], [x, y - 1], [x, y - 2], [x, y - 3]]
  end

  if y < input[0].size - 3
    output << [[x, y], [x, y + 1], [x, y + 2], [x, y + 3]]
  end
  
  output
end

def one(input)
  count = 0
  input.size.times do |x|
    input[0].size.times do |y|
      directions = get_directions(x, y, input)

      count += directions.count { |direction| direction.map { |a, b| input[a][b] }.join("") == "XMAS" }
    end
  end

  count
end

def two(input)
  count = 0
  (input.size - 2).times do |a|
    (input[0].size - 2).times do |b|
      x = a + 1
      y = b + 1

      m = input[x][y]

      next if m != "A"

      tl = input[x - 1][y - 1]
      tr = input[x - 1][y + 1]
      bl = input[x + 1][y - 1]
      br = input[x + 1][y + 1]

      if (tl + tr == "MM" || tr + br == "MM" || bl + br == "MM" || bl + tl == "MM") && (tl + tr == "SS" || tr + br == "SS" || bl + br == "SS" || bl + tl == "SS")
        count += 1
      end
    end
  end

  count
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
