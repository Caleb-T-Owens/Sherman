require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input = input_lines("aoc-test.txt")

def one(input, w, h)
  screen = h.times.map { w.times.map { false } }

  input.each do |instr|
    if instr.start_with?("rect ")
      x, y = instr[5..].split("x").map(&:to_i)

      y.times do |y|
        x.times do |x|
          screen[y][x] = true
        end
      end
    elsif instr.start_with?("rotate column ")
      col, amount = instr[16..].split(" by ").map(&:to_i)
      screen2 = screen.map(&:dup)
      h.times do |y|
        screen2[(y + amount) % h][col] = screen[y][col]
      end
      screen = screen2
    elsif instr.start_with?("rotate row ")
      row, amount = instr[13..].split(" by ").map(&:to_i)
      screen2 = screen.map(&:dup)
      w.times do |x|
        screen2[row][(x + amount) % w] = screen[row][x]
      end
      screen = screen2
    end
  end

  screen.sum { |a| a.sum { _1 ? 1 : 0 } }
end

def print_screen(screen)
  screen.each do |line|
    line.each do |pixel|
      if pixel
        print "#"
      else
        print "."
      end
    end

    print "\n"
  end
end

def two(input, w, h)
  screen = h.times.map { w.times.map { false } }

  input.each do |instr|
    if instr.start_with?("rect ")
      x, y = instr[5..].split("x").map(&:to_i)

      y.times do |y|
        x.times do |x|
          screen[y][x] = true
        end
      end
    elsif instr.start_with?("rotate column ")
      col, amount = instr[16..].split(" by ").map(&:to_i)
      screen2 = screen.map(&:dup)
      h.times do |y|
        screen2[(y + amount) % h][col] = screen[y][col]
      end
      screen = screen2
    elsif instr.start_with?("rotate row ")
      row, amount = instr[13..].split(" by ").map(&:to_i)
      screen2 = screen.map(&:dup)
      w.times do |x|
        screen2[row][(x + amount) % w] = screen[row][x]
      end
      screen = screen2
    end
  end

  print_screen(screen)
end

puts "test:"
puts one(test_input, 7, 3)
# puts two(test_input)
puts "input:"
puts one(input, 50, 6)
two(input, 50, 6)
