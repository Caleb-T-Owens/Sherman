require "parallel"

input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  x = input.find_index { _1.include?("^") }
  y = input[x].split("").find_index("^")
  loops(input, [x, y]).size
end

def loops(input, start, blocker = [])
  facing = :up
  count = 0

  x, y = start

  visited = { }

  loop do
    if facing == :up
      x -= 1
    elsif facing == :down
      x += 1
    elsif facing == :left
      y -= 1
    elsif facing == :right
      y += 1
    end

    break if x < 0 || x >= input.size || y < 0 || y >= input[0].size

    if input[x][y] == "#" || (x == blocker[0] && y == blocker[1])
      if facing == :up
        x += 1
        facing = :right
      elsif facing == :down
        x -= 1
        facing = :left
      elsif facing == :left
        y += 1
        facing = :up
      elsif facing == :right
        y -= 1
        facing = :down
      end
      next
    end

    if visited[[x, y]]&.include?(facing)
      return :looping
    end

    visited[[x, y]] ||= []
    visited[[x, y]] << facing
  end

  visited
end

def two(input)
  x = input.find_index { _1.include?("^") }
  y = input[x].split("").find_index("^")
  positions = loops(input, [x, y])

  Parallel.map(positions.keys, in_processes: 16) do |position|
    next if input[position[0]][position[1]] == "^"

    loops(input, [x, y], position) == :looping
  end.sum { _1 ? 1 : 0 }
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
