input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def add((a1, a2), (b1, b2))
  [a1 + b1, a2 + b2]
end

DIRECTIONS = {
  up: [-1, 0],
  down: [+1, 0],
  left: [0, -1],
  right: [0, +1],
}

def d(dir)
  DIRECTIONS[dir]
end

def dirs()= DIRECTIONS.keys

def parse_input(input)
  start = nil
  finish = nil
  input.each_with_index do |row, x|
    row.split("").each_with_index do |char, y|
      if char == "S"
        start = [x, y]
      end
      if char == "E"
        finish = [x, y]
      end
      break if start && finish
    end
    break if start && finish
  end

  path = []
  path_hash = {}
  current = start
  while current
    path << current
    path_hash[current] = path_hash.size

    after = nil
    dirs.each do |dir|
      x, y = add(current, d(dir))
      over = input[x] && input[x][y]
      if (over == "." || over == "E") && !path_hash.key?([x, y])
        after = [x, y]
        break
      end
    end

    current = after
  end

  return start, finish, path, path_hash
end

def poscone(center, radius)
  poses = []

  ((-radius)..radius).each do |x|
    ((-radius)..radius).each do |y|
      distance = (x.abs + y.abs)
      next if distance <= 1
      next if distance > radius

      poses << [add(center, [x, y]), distance]
    end
  end

  poses
end

def one(input, radius = 2)
  start, finish, path, path_hash = parse_input(input)

  cheats = {}
  sum = 0

  path.each do |road|
    current = path_hash[road]

    poscone(road, radius).each do |(over_pos, distance)|
      over = path_hash[over_pos]

      # Break if it's not a cheat candidate
      next unless over

      saves = over - current - distance
      if saves > 0
        cheats[saves] ||= 0
        cheats[saves] += 1
        if saves >= 100
          sum += 1
        end
      end
    end
  end

  sum
end

def two(input)
  one(input, 20)
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
