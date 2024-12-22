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

def dks()= DIRECTIONS.keys
def dvs()= DIRECTIONS.values

NUMBER_PAD = [
  ["7", "8", "9"],
  ["4", "5", "6"],
  ["1", "2", "3"],
  [nil, "0", "A"]
]

DIRECTION_PAD = [
  [nil, :up, "A"],
  [:left, :down, :right]
]

def path_between(b, pad, (cx, cy), acc)
  return [] if acc.size > 7
  return [acc] if [cx, cy] == b

  routes = []

  dvs.each do |dir|
    ox, oy = add([cx, cy], dir)
    next if ox < 0 || oy < 0
    next if ox > 4 || oy > 3
    next if acc.include? [ox, oy]
    next if pad[ox].nil? || pad[ox][oy].nil?

    routes.push(*path_between(b, pad, [ox, oy], [*acc, [ox, oy]]))
  end

  routes
end

def type_pos(pad, type)
  pos = nil
  pad.each_with_index do |row, x|
    row.each_with_index do |t, y|
      if type == t
        pos = [x, y]
      end
      break if pos
    end
    break if pos
  end
  pos
end

def sub((ax, ay), (bx, by))
  [ax - bx, ay - by]
end

def direction(a, b)
  {
    [-1, 0] => :up,
    [+1, 0] => :down,
    [0, -1] => :left,
    [0, +1] => :right
  }[sub(a, b)]
end

# def score_path(path)
#   facing = :east
#   sum = 0

#   path.each_with_index do |point, index|
#     sum += 1
#     next_point = path[index + 1]
#     next unless next_point
#     next_direction = direction(point, next_point)
#     if next_direction != facing
#       facing = next_direction
#       if index == 0
#         sum += 1
#       else
#         sum += 1000
#       end
#     end
#   end
#   sum
# end

def take_shortest(list)
  shortest = list.map(&:size).min
  list.select { _1.size == shortest }
end

def paths_between_each(pad)
  types = pad.flatten.reject(&:nil?)
  paths = {}
  types.permutation(2) do |(a, b)|
    ap = type_pos(pad, a)
    bp = type_pos(pad, b)
    paths[[a, b]] = take_shortest(path_between(bp, pad, ap, [ap]))
      .map { |pth| [*pth.each_cons(2).map { direction(_2, _1) }, "A"] }
  end
  paths
end

NUM_PATHS = paths_between_each(NUMBER_PAD)
DIR_PATHS = paths_between_each(DIRECTION_PAD)

def print_path(path)
  path.each do |path|
    char = {
      up: "^",
      down: "v",
      left: "<",
      right: ">"
    }[path]
    char ||= path

    print char
  end
  print "\n"
end

# Global cache! Conversion between currencies got too hard
CACHE = {}
def county_count(a, b, depth, map)
  cv = CACHE[[a, b, depth, map]]
  return cv if cv

  if depth.zero?
    return map[[a, b]]&.first&.size || 1
  end

  pointss = map[[a, b]] || [["A"]]
  pointss = pointss.map { ["A", *_1] }

  out = pointss.map do |points|
    points
      .each_cons(2)
      .sum { |(x, y)| county_count(x, y, depth - 1, DIR_PATHS) }
  end.min

  CACHE[[a, b, depth, map]] = out
  out
end

def one(input)
  out = input.sum do |target|
    min_size = ["A", *target.split("")]
      .each_cons(2)
      .sum { |(x, y)| county_count(x, y, 2, NUM_PATHS) }
    min_size * target.to_i
  end
  out
end

def two(input)
  out = input.sum do |target|
    min_size = ["A", *target.split("")]
      .each_cons(2)
      .sum { |(x, y)| county_count(x, y, 25, NUM_PATHS) }
    min_size * target.to_i
  end
  out
end

puts "test:"
puts one(test_input)
puts two(test_input)

puts "input:"
puts one(input)
puts two(input)