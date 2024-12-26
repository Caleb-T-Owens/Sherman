require "enumerator"
require "set"

input = File.readlines("aoc-input.txt", chomp: true)
test_input = File.readlines("aoc-test.txt", chomp: true)

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

  def keys()= @nodes.keys

  def each(&block)
    @nodes.each(&block)
  end
end

def build_graph(input)
  graph = Graph.new
  input.each do |entry|
    a, b = entry.split("-")

    unless graph.key? a
      graph.add(key: a, value: true, neighbours: Set.new)
    end
    unless graph.key? b
      graph.add(key: b, value: true, neighbours: Set.new)
    end

    graph.get(a).neighbours << b
    graph.get(b).neighbours << a
  end
  graph
end

def one(input)
  graph = build_graph(input)
  triplets = Set.new
  graph.each do |key, value|
    neighbours = value.neighbours.map { [_1, graph.get(_1).neighbours] }.to_h
    neighbours.to_a.combination(2) do |((ak, ans), (bk, bns))|
      if bns.include?(ak) && ans.include?(bk)
        triplets << Set[key, ak, bk]
      end
    end
  end
  starts_with_t = triplets.filter { |set| set.any? { _1.start_with? "t" } }
  starts_with_t.size
end

# algorithm BronKerbosch1(R, P, X) is
# if P and X are both empty then
#   report R as a maximal clique
# for each vertex v in P do
#   BronKerbosch1(R ⋃ {v}, P ⋂ N(v), X ⋂ N(v))
#   P := P \ {v}
#   X := X ⋃ {v}
def bonkers(graph, r, p, x, out)
  out << r if p.empty? && x.empty?

  p.each do |v|
    neighbours = graph.get(v).neighbours
    bonkers(graph, r + [v], p & neighbours, x & neighbours, out)
    p = p - [v]
    x = x + [v]
  end
end

def two(input)
  graph = build_graph(input)

  out = Set.new
  bonkers(graph, Set.new, graph.keys.to_set, Set.new, out)
  largest = Set.new
  out.each do |set|
    if set.size > largest.size
      largest = set
    end
  end

  largest.sort.join(",")
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
