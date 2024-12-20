require "enumerator"
require "json"

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

class GraphNode
  attr_accessor :value
  attr_accessor :key
  attr_accessor :neighbours

  def initialize(key:, value:, neighbours:)
    @value = value
    @neighbours = neighbours
  end
end

class Graph
  include Enumerable

  class Error < StandardError; end
  class NodeAlreadyAdded < Error; end
  class NodeNotFound < Error; end

  def initialize
    @nodes = {}
  end

  def add(key:, value:, neighbours:)
    # Validate neighbours
    raise NodeAlreadyAdded, "Node #{key} already exists" if @nodes[key]
    neighbours.each do |neighbour|
      if @nodes[neighbour].nil?
        raise NodeNotFound, "Neighbour #{neighbour} not found"
      end
    end

    @nodes[key] = GraphNode.new(key:, value:, neighbours:)

    neighbours.each do |neighbour|
      @nodes[neighbour].neighbours << key
    end
  end

  def remove(key:)
    node = @nodes[key]
    raise NodeNotFound, "Node #{neighbour} not found" if node.nil?

    @nodes.delete(key)

    node.neighbours.each do |neighbour|
      @nodes[neighbour].neighbours.delete(key)
    end
  end

  def get(key)
    node = @nodes[key]
    raise NodeNotFound, "Node #{neighbour} not found" if node.nil?
    node
  end

  def [](key)
    get(key).value
  end

  def []=(key, other)
    node = @nodes[key]
    raise NodeNotFound, "Node #{neighbour} not found" if node.nil?
    node.value = other
  end

  def key?(key)
    @nodes.key?(key)
  end

  def each(&block)
    @nodes.each(&block)
  end
end

def build_graph(input)
  graph = Graph.new

  input.each_with_index do |row, x|
    row.split("").each_with_index do |letter, y|
      next if letter == "#"

      neighbours = dirs.filter_map do |dir|
        neighbour_pos = add([x, y], d(dir))
        if graph.key?(neighbour_pos)
          neighbour_pos
        end
      end

      graph.add(key: [x, y], value: {}, neighbours:)
    end
  end

  graph
end

# def remove_tails(graph)
#   tails = graph.select do |key, node|
#     node.neighbours.size == 1
#   end.map(&:first).to_a

#   loop do
#     break if tails.empty?

#     tail = tails.pop
#     next unless graph.key?(tail)
#     tails.push(*graph.get(tail).neighbours)
#     graph.remove(key: tail)
#   end
# end

$smallest_score = 236824

def find_paths(graph, point, acc, opath, finish)
  score = score_path(opath)
  if score >= $smallest_score
    return [], []
  end

  if point == finish
    $smallest_score = score
    pp "found!"
    pp opath.size
    pp $smallest_score
    return [], [opath]
  end

  # this_path = acc.dup
  # this_path[point] = true
  this_opath = opath.dup
  this_opath << point

  paths = []
  opaths = []

  ns = graph.get(point).neighbours.reject { this_opath.reverse_each.include? _1 }
  ns = if this_opath.size >= 2
    same_dir = ns.find { |n| heading(this_opath[-2], this_opath[-1]) == heading(this_opath[-1], n) }
    if same_dir.nil?
      ns
    else
      ns.delete(same_dir)
      [same_dir, *ns]
    end
  else
    ns
  end

  ns.each do |neighbour|
    # next if this_path.key? neighbour

    nps, ops = find_paths(graph, neighbour, {}, this_opath, finish)
    #paths.push(*nps)
    opaths.push(*ops)
  end

  return paths, opaths
end

def find_start_and_finish(input)
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

  return start, finish
end

HEADINGS = {
  [-1, 0] => :north,
  [+1, 0] => :south,
  [0, -1] => :west,
  [0, +1] => :east,
}

# From -> To
def heading((ax, ay), (bx, by))
  HEADINGS[[(bx - ax), (by - ay)]]
end

def score_path(path)
  facing = :east
  sum = 0
  path.each_with_index do |point, index|
    sum += 1
    next_point = path[index + 1]
    next unless next_point
    next_direction = heading(point, next_point)
    if next_direction != facing
      facing = next_direction
      sum += 1000
    end
  end
  sum
end

def one(input)
  $smallest_score = Float::INFINITY
  graph = build_graph(input)
  pp graph.count { _1[1].neighbours.size > 2}
  start, finish = find_start_and_finish(input)
  found = find_paths(graph, start, {}, [], finish)
  puts JSON.generate(found[1])
  pp found.size
  min_cost = found[1].map do |path|
    score_path(path)
  end.min
  min_cost
end

def two(input)
  input.size
end

puts "test:"
puts "p1.a:"
puts one(test_input)
puts "p1.b:"
puts one("#################
#...#...#...#..E#
#.#.#.#.#.#.#.#.#
#.#.#.#...#...#.#
#.#.#.#.###.#.#.#
#...#.#.#.....#.#
#.#.#.#.#.#####.#
#.#...#.#.#.....#
#.#.#####.#.###.#
#.#.#.......#...#
#.#.###.#####.###
#.#.#...#.....#.#
#.#.#.#####.###.#
#.#.#.........#.#
#.#.#.#########.#
#S#.............#
#################".lines)
puts "p2:"
puts two(test_input)
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
