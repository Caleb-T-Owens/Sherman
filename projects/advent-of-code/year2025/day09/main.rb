require "../lib/main.rb"
require "enumerator"
require "chunky_png"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  input.map { _1.split(",").map(&:to_i) }.combination(2).map { ((_1[0][0] - _1[1][0] + 1).abs * (_1[0][1] - _1[1][1] + 1).abs) }.max
end

def compute_surface(input, (dx, dy))
  points = input.map { _1.split(",").map(&:to_i) }

  x_map = points.map { _1[0] }.uniq.sort_by { _1 }.each.with_index.to_h
  y_map = points.map { _1[1] }.uniq.sort_by { _1 }.each.with_index.to_h

  edges = Set.new
  points.each_cons(2) do |(a, b)|
    add_side(edges, map_p(x_map, y_map, a), map_p(x_map, y_map, b))
  end
  add_side(edges, map_p(x_map, y_map, points[-1]), map_p(x_map, y_map, points[0]))

  surface = edges.dup
  # flood fill :D
  starts = [[map_p(x_map, y_map, points[0])[0] + dx, map_p(x_map, y_map, points[0])[1] + dy]]
  surface << starts[0]
  loop do
    if starts.size.zero?
      break
    end

    x, y = starts.pop

    CARDINALS.each do |(dx, dy)|
      p = [x + dx, y + dy]
      if !surface.include?(p)
        starts << p
        surface << p
      end
    end
  end

  { points:, x_map:, y_map:, edges:, surface: }
end

def two(input, (dx, dy))
  data = compute_surface(input, [dx, dy])
  points = data[:points]
  x_map = data[:x_map]
  y_map = data[:y_map]
  surface = data[:surface]

  max = 0
  max_rect = nil

  points.combination(2).each do |p1, p2|
    area = ((p1[0] - p2[0]).abs + 1) * ((p1[1] - p2[1]).abs + 1)

    mapped_a = map_p(x_map, y_map, p1)
    mapped_b = map_p(x_map, y_map, p2)

    if all_inside(surface, mapped_a, mapped_b)
      if area > max
        max = area
        max_rect = [mapped_a, mapped_b]
      end
    end
  end

  if ENV["GIMMIE_IMG"]
    visualize_surface(data, "output.png", max_rect)
  end
  max
end

def map_p(x_map, y_map, (x, y))
  [x_map[x], y_map[y]]
end

def all_inside(surface, a, b, debug = false)
  min_x, max_x = [a[0], b[0]].minmax
  min_y, max_y = [a[1], b[1]].minmax

  (min_x..max_x).each do |x|
    if !surface.include?([x, a[1]])
      return false
    end
    if !surface.include?([x, b[1]])
      return false
    end
  end

  (min_y..max_y).each do |y|
    if !surface.include?([a[0], y])
      return false
    end
    if !surface.include?([b[0], y])
      return false
    end
  end
  true
end

def add_side(edges, a, b)
  ([a[0], b[0]].min..[a[0], b[0]].max).each do |x|
    ([a[1], b[1]].min..[a[1], b[1]].max).each do |y|
      edges << [x, y]
    end
  end
end

def visualize_surface(data, filename, max_rect = nil)
  points = data[:points]
  x_map = data[:x_map]
  y_map = data[:y_map]
  edges = data[:edges]
  surface = data[:surface]

  width = x_map.size
  height = y_map.size

  png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::WHITE)
  surface.each do |(x, y)|
    png[x, y] = ChunkyPNG::Color.rgba(173, 216, 230, 255)
  end
  edges.each do |(x, y)|
    png[x, y] = ChunkyPNG::Color.rgba(0, 0, 139, 255)
  end

  if max_rect
    a, b = max_rect
    min_x, max_x = [a[0], b[0]].minmax
    min_y, max_y = [a[1], b[1]].minmax

    (min_x..max_x).each do |x|
      (min_y..max_y).each do |y|
        png[x, y] = ChunkyPNG::Color.rgba(255, 215, 0, 255)
      end
    end
  end

  points.each do |p|
    png[*map_p(x_map, y_map, p)] = ChunkyPNG::Color.rgba(255, 0, 0, 255)
  end

  png.save(filename)
end

puts "test:"
puts one(test_input)
puts two(test_input, [1, 1])
puts "input:"
puts one(input)
# Let's just pretend that we have a more elegant way of finding a point _in_ the
# polygon to start the flood fill
puts two(input, [-16, -16])