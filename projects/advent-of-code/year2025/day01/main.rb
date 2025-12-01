require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input = input_lines("aoc-test.txt")

def one(input)
  poses = [50]
  lxc = 0
  input.each do |pos|
    r = pos[1..].to_i

    if pos[0] == "R"
      a = (poses[-1] + r) % 100
      if a == 0
        lxc += 1
      end
      poses << a
    else
      a = (poses[-1] - r) % 100
      if a == 0
        lxc += 1
      end
      poses << a
    end
  end

  lxc
end

def two(input)
  poses = [50]
  lxc = 0
  input.each do |pos|
    r = pos[1..].to_i

    if pos[0] == "R"
      a = (poses[-1] + r) % 100
      lxc += (poses[-1] + r) / 100
      poses << a
    else
      a = (poses[-1] - r) % 100
      lxc += r / 100
      if poses[-1] != 0 && r % 100 >= poses[-1]
        lxc += 1
      end
      poses << a
    end
  end

  lxc
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
