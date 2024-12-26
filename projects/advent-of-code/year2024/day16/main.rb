require "enumerator"
require "set"
require "json"

input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def add((a1, a2), (b1, b2))
  [a1 + b1, a2 + b2]
end

DIRECTIONS = {
  north: [-1, 0],
  south: [+1, 0],
  west: [0, -1],
  east: [0, +1],
}

def d(dir)
  DIRECTIONS[dir]
end

def dks()= DIRECTIONS.keys
def dvs()= DIRECTIONS.values

class GraphNode
  attr_accessor :value
  attr_accessor :key
  attr_accessor :neighbours

  def initialize(key:, value:, neighbours:)
    @key = key
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

  def remove(key)
    node = @nodes[key]
    raise NodeNotFound, "Node #{key} not found" if node.nil?

    @nodes.delete(key)

    node.neighbours.each do |neighbour|
      @nodes[neighbour].neighbours.delete(key)
    end
  end

  def get(key)
    node = @nodes[key]
    raise NodeNotFound, "Node #{key} not found" if node.nil?
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

def build_graph(input)
  graph = Graph.new

  input.each_with_index do |row, x|
    row.split("").each_with_index do |char, y|
      if ["S", "E", "."].include? char
        graph.add(key: [[x, y], :north], value: Float::INFINITY, neighbours: [])
        graph.add(key: [[x, y], :south], value: Float::INFINITY, neighbours: [])
        graph.add(key: [[x, y], :east], value: Float::INFINITY, neighbours: [])
        graph.add(key: [[x, y], :west], value: Float::INFINITY, neighbours: [])
        graph.get([[x, y], :north]).neighbours.push([[x, y], :east], [[x, y], :west])
        graph.get([[x, y], :south]).neighbours.push([[x, y], :east], [[x, y], :west])
        graph.get([[x, y], :east]).neighbours.push([[x, y], :north], [[x, y], :south])
        graph.get([[x, y], :west]).neighbours.push([[x, y], :north], [[x, y], :south])
      end
    end
  end

  input.each_with_index do |row, x|
    row.split("").each_with_index do |char, y|
      if ["S", "E", "."].include? char
        DIRECTIONS.each do |dir, vec|
          ox, oy = add([x, y], vec)
          over = input[x][y]
          next unless graph.key? [[ox, oy], dir]
          if ["S", "E", "."].include? over
            graph.get([[x, y], dir]).neighbours.push([[ox, oy], dir])
            graph.get([[ox, oy], dir]).neighbours.push([[x, y], dir])
          end
        end
      end
    end
  end

  graph
end

def score_graph(graph, current, cscore)
  here = graph.get(current)
  here.value = cscore

  here.neighbours.each do |key|
    neighbour = graph.get(key)
    nscore = if key.last == current.last
      1 + cscore
    else
      1000 + cscore
    end
    if neighbour.value > nscore
      score_graph(graph, key, nscore)
    end
  end
end

def score_graph_bf(graph, start)
  graph.get(start).value = 0
  currents = [start]

  until currents.empty?
    nexts = []
    currents.each do |current|
      here = graph.get(current)
      here.neighbours.each do |key|
        neighbour = graph.get(key)
        nscore = if key.last == current.last
          1 + here.value
        else
          1000 + here.value
        end
        if neighbour.value > nscore
          neighbour.value = nscore
          nexts << key
        end
      end
    end

    currents = nexts
  end
end

def one(input)
  start, finish = find_start_and_finish(input)
  graph = build_graph(input)
  score_graph_bf(graph, [start, :east])
  [
    graph[[finish, :north]],
    graph[[finish, :south]],
    graph[[finish, :east]],
    graph[[finish, :west]]
  ].min
end

def find_paths(graph, points)
  heads = points
  found = heads.to_set

  until heads.empty?
    next_heads = []
    heads.each do |hk|
      head = graph.get(hk)
      if head.value.zero?
        next
      end
      ns = head.neighbours.map { graph.get(_1) }
      ns = ns.select { _1.value < head.value }
      ns.each do |n|
        found << n.key[0]
        next_heads << n.key
      end
    end

    heads = next_heads.uniq
  end

  found
end

def two(input)
  start, finish = find_start_and_finish(input)
  graph = build_graph(input)
  score_graph_bf(graph, [start, :east])
  fs = [
    graph.get([finish, :north]),
    graph.get([finish, :south]),
    graph.get([finish, :east]),
    graph.get([finish, :west])
  ]
  min = fs.map { _1.value }.min
  fs = fs.select { |a| a.value == min }
  # Who knows why this should be -1
  find_paths(graph, fs.map(&:key)).size - 1
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
puts "p2.b:"
puts two("#################
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
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
