require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")
test_input_2 =  input_lines("aoc-test-2.txt")

def one(input)
  g = input.map { a, b = _1.split(": "); [a, b.split(" ")]}

  dfs({}, g, "you", "out")
end

def dfs(ch, g, now, target)
  if c = ch[[g, now, target]]
    return c
  end

  if now == target
    return ch[[g, now, target]] = 1
  end
  if now == "out"
    return ch[[g, now, target]] = 0
  end

  ch[[g, now, target]] = g.find { _1[0] == now }[1].sum do
     dfs(ch, g, _1, target)
  end
end

def two(input)
  g = input.map { a, b = _1.split(": "); [a, b.split(" ")]}

  ch = {}
  s_to_f = dfs(ch, g, "svr", "fft")
  s_to_d = dfs(ch, g, "svr", "dac")
  d_to_f = dfs(ch, g, "dac", "fft")
  f_to_d = dfs(ch, g, "fft", "dac")
  d_to_o = dfs(ch, g, "dac", "out")
  f_to_o = dfs(ch, g, "fft", "out")

  s_to_d * d_to_f * f_to_o + s_to_f * f_to_d * d_to_o
end

puts "test:"
puts one(test_input)
puts two(test_input_2)
puts "input:"
puts one(input)
puts two(input)
