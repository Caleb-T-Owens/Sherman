require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

SIDES = [
  [-1, -1],
  [-1, 0],
  [-1, 1],
  [0, -1],
  [0, 1],
  [1, -1],
  [1, 0],
  [1, 1],
]

def one(input)
  i = input.map { _1.dup }
  height = input.size
  width = input[0].size
  height.times do |y|
    width.times do |x|
      if input[y][x] == "@"
        covered = 0
        SIDES.each do |(dx, dy)|
          if (x + dx >= 0 && x + dx < width) && (y + dy >= 0 && y + dy < height)
            if input[y + dy][x + dx] == "@"
              covered += 1
            end
          end
        end
        if covered < 4
          i[y][x] = "x"
        end
      end
    end
  end

  i.sum { _1.count("x") }
end

def two(input)
  i = input.map { _1.dup }
  height = input.size
  width = input[0].size
  last_count = 0
  loop do
    height.times do |y|
      width.times do |x|
        if input[y][x] == "@"
          covered = 0
          SIDES.each do |(dx, dy)|
            if (x + dx >= 0 && x + dx < width) && (y + dy >= 0 && y + dy < height)
              if i[y + dy][x + dx] == "@"
                covered += 1
              end
            end
          end
          if covered < 4
            i[y][x] = "x"
          end
        end
      end
    end
    current = i.sum { _1.count("x") }
    if current == last_count
      last_count = current
      break
    end
    last_count = current
  end

  last_count
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
