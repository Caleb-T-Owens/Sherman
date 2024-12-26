require "enumerator"

input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def parse_input(input)
  input.map do |i|
    a, b = i.split(" ")
    pos = a.split("=").last.split(",").map(&:to_i)
    v = b.split("=").last.split(",").map(&:to_i)

    { pos:, v: }
  end
end

def move_bot(bot, width, height)
  bot[:pos][0] = (bot[:pos][0] + bot[:v][0]) % (width)
  bot[:pos][1] = (bot[:pos][1] + bot[:v][1]) % (height)
end

def quadrents(width, height)
  [
    [0..(width / 2 - 1).floor,      0..(height / 2 - 1).floor],
    [(width / 2 + 1).ceil..(width - 1), 0..(height / 2 - 1).floor],
    [0..(width / 2 - 1).floor,      (height / 2 + 1).ceil..(height - 1)],
    [(width / 2 + 1).ceil..(width - 1), (height / 2 + 1).ceil..(height - 1)]
  ]
end

def print_board(bots, width, height)
  board = height.times.map { ["."] * width }
  bots.each do |bot|
    entry = board[bot[:pos][1]][bot[:pos][0]].to_i
    board[bot[:pos][1]][bot[:pos][0]] = (entry + 1).to_s
  end
  puts board.map { _1.join("") }
end

def one(input, width, height)
  bots = parse_input(input)
  100.times do
    bots.each do |bot|
      move_bot bot, width, height
    end
  end
  quadrents(width, height).map do |quadrent|
    bots.select do |bot|
      quadrent[0].include?(bot[:pos][0]) && quadrent[1].include?(bot[:pos][1])
    end.size
  end.inject(:*)
end

def qinc(b, q)= q[0].include?(b[:pos][0]) && q[1].include?(b[:pos][1])

def two(input, width, height)
  bots = parse_input(input)
  qs = quadrents(width, height)
  count = 0
  loop do
    count += 1
    bots.each do |bot|
      move_bot bot, width, height
    end

    left = bots.select { qinc(_1, qs[0]) }.size
    right = bots.select { qinc(_1, qs[1]) }.size
    bleft = bots.select { qinc(_1, qs[2]) }.size
    bright = bots.select { qinc(_1, qs[3]) }.size

    if bots.size == bots.map { _1[:pos] }.uniq.size
      break
    end
  end

  if ENV["DEBUG_PRINT"] == "1"
    print_board(bots, width, height)
  end

  count
end

puts "test:"
puts "p1:"
puts one(test_input, 11, 7)
# puts two(test_input, 11, 7)
puts "input:"
puts "p1:"
puts one(input, 101, 103)
puts "p2:"
puts two(input, 101, 103)
