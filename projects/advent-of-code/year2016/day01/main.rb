require "set"

input = File.read("aoc-input.txt", chomp: true)

def parse_input(input)
  input.split(", ").map { { dir: _1[0], dist: _1[1..].to_i} }
end

def handle_dir(x, dir)
  if x == "L"
    case dir
    when :N
      :W
    when :W
      :S
    when :S
      :E
    when :E
      :N
    end
  else
    case dir
    when :N
      :E
    when :E
      :S
    when :S
      :W
    when :W
      :N
    end
  end
end

def one(input)
  i = parse_input(input)
  x = 0
  y = 0
  facing = :N
  i.each do |i|
    facing = handle_dir(i[:dir], facing)

    case facing
    when :N
      y += i[:dist]
    when :S
      y -= i[:dist]
    when :E
      x += i[:dist]
    when :W
      x -= i[:dist]
    end
  end

  { x:, y:, facing: }
  
  x.abs + y.abs
end

def two(input)
  i = parse_input(input)

  visited = {}

  x = 0
  y = 0
  facing = :N
  i.each do |i|
    facing = handle_dir(i[:dir], facing)

    should_exit = false

    (0...i[:dist]).each do
      case facing
      when :N
        y += 1
      when :S
        y -= 1
      when :E
        x += 1
      when :W
        x -= 1
      end
      if visited[[x, y]].nil?
        visited[[x, y]] = 1
      else
        visited[[x, y]] += 1
      end

      if visited[[x, y]] == 2
        should_exit = true
        break
      end
    end

    if should_exit
      break
    end
  end

  # pp visited

  x.abs + y.abs
end

# puts "test:"
# puts "p2.a:"
# puts one(")")
puts "p2.b:"
puts two("R8, R4, R4, R8")
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
