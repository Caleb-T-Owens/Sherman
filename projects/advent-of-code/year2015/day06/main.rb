input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def parse_input(i)
  i.map do |line|
    out = {}
    if line.start_with? "turn on "
      out[:type] = :on
      line.delete_prefix!("turn on ")
    elsif line.start_with? "turn off "
      out[:type] = :off
      line.delete_prefix!("turn off ")
    else
      out[:type] = :toggle
      line.delete_prefix!("toggle ")
    end

    start, finish = line.split(" through ").map { _1.split(",").map(&:to_i) }

    out[:x] = (start[0]..finish[0])
    out[:y] = (start[1]..finish[1])

    out
  end
end

def one(i)
  sum = 0

  (0..999).each do |x|
    (0..999).each do |y|
      v = false

      i.each do |entry|
        next unless entry[:x].include?(x) && entry[:y].include?(y)
        if entry[:type] == :on
          v = true
        elsif entry[:type] == :off
          v = false
        else
          v = !v
        end
      end

      if v
        sum += 1
      end
    end
  end

  sum
end

def two(i)
  map = {}

  i.each do |entry|
    sx, sy = entry[:start]
    fx, fy = entry[:finish]

    (sx..fx).each do |x|
      (sy..fy).each do |y|
        if entry[:type] == :on
          map[[x, y]] = (map[[x, y]] || 0) + 1
        elsif entry[:type] == :off
          map[[x, y]] = [(map[[x, y]] || 0) - 1, 0].max
        else
          map[[x, y]] = (map[[x, y]] || 0) + 2
        end
      end
    end
  end

  map.values.sum
end

parsed_input = parse_input(input)

puts "test:"
# puts one(test_input)
# puts two(test_input)
puts "input:"
puts one(parsed_input)
puts two(parsed_input)
