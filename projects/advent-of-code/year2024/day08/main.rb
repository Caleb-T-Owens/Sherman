input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def solve(input, range = (1..1))
  nodes = {}
  antinodes = {}

  input.size.times do |x|
    input[0].size.times do |y|
      node = input[x][y]
      if node != "."
        nodes[node] ||= []
        nodes[node] << [x, y]
      end
    end
  end

  nodes.each do |_type, positions|
    positions.combination(2) do |(ax, ay), (bx, by)|
      range.each do |m|
        dx = (ax - bx) * m
        dy = (ay - by) * m

        ax2 = ax + dx
        ay2 = ay + dy
        bx2 = bx - dx
        by2 = by - dy

        a_out = false
        b_out = false

        if (0...input.size).include?(ax2) && (0...input[0].size).include?(ay2)
          antinodes[[ax2, ay2]] = true
        else
          a_out = true
        end

        if (0...input.size).include?(bx2) && (0...input[0].size).include?(by2)
          antinodes[[bx2, by2]] = true
        else
          b_out = true
        end

        if a_out && b_out
          break
        end
      end
    end
  end

  if ENV["DEBUG_PRINT"] == "1"
    input.size.times do |x|
      input[0].size.times do |y|
        if antinodes[[x, y]]
          print "#"
        else
          print input[x][y]
        end
      end
      print "\n"
    end
  end

  antinodes.size
end

def one(input)
  solve(input)
end

def two(input)
  solve(input, (0..51))
end

puts "test:"
puts "p1:"
puts one(test_input)
puts "p2:"
puts two(test_input)
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
