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

def distances(map, start)
  points = [start]
  distance = 0

  loop do
    break if points.empty?
    next_points = {}

    points.each do |point|
      map[point] = distance

      dirs.each do |dir|
        over_pos = add(point, d(dir))
        over = map[over_pos]
        next if over.nil?
        next if over == "#"
        if over > distance
          next_points[over_pos] = true
        end
      end
    end

    points = next_points.keys
    distance += 1
  end
end

def find_paths(map, point, acc)
  if map[point].nil?
    return []
  end
  if map[point] == "#"
    return []
  end
  if map[point] == 0
    return [acc]
  end

  routes = []

  dirs.each do |dir|
    over_pos = add(point, d(dir))
    next if map[over_pos].nil?
    next if map[over_pos] == "#"
    if map[over_pos] < map[point]
      routes.push(*find_paths(map, over_pos, [*acc, point]))
    end
  end

  routes
end

def one(input, take)
  points = input.map { _1.split(",").map(&:to_i) }.first(take)
  max_x = points.map { _1[0] }.max
  max_y = points.map { _1[1] }.max
  point_map = points.map { [_1, true] }.to_h

  map = {}

  (max_x + 1).times do |x|
    (max_y + 1).times do |y|
      if point_map.include? [x, y]
        map[[x, y]] = "#"
      else
        map[[x, y]] = 9999
      end
    end
  end

  distances(map, [0, 0])

  paths = find_paths(map, [max_x, max_y], [])
  shortest = paths.map(&:size).min

  shortest
end

def two(input, take)
  points = input.map { _1.split(",").map(&:to_i) }
  max_x = points.map { _1[0] }.max
  max_y = points.map { _1[1] }.max

  current_set = points.first(take)

  loop do
    point_map = current_set.map { [_1, true] }.to_h
    map = {}
    pp current_set.last

    (max_x + 1).times do |x|
      (max_y + 1).times do |y|
        if point_map.include? [x, y]
          map[[x, y]] = "#"
        else
          map[[x, y]] = 9999
        end
      end
    end

    distances(map, [0, 0])

    paths = find_paths(map, [max_x, max_y], [])
    if paths.size == 0
      break
    end

    take += 1
    current_set = points.take(take)
  end

  current_set.last.join(",")
end

puts "test:"
puts "p1:"
puts one(test_input, 12)
puts "p2:"
puts two(test_input, 12)
puts "input:"
puts "p1:"
puts one(input, 1024)
puts "p2:"
puts two(input, 1024)
