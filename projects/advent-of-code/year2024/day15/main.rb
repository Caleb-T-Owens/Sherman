input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

$d = {
  "^" => [-1, 0],
  "v" => [+1, 0],
  "<" => [0, -1],
  ">" => [0, +1],
}

def add((a1, a2), (b1, b2))
  [a1 + b1, a2 + b2]
end

def parse_input(input)
  board, instructions = input.split("\n\n")

  instructions = instructions.split.join("")

  sparse_board = {}
  bot = nil
  board.split.each_with_index do |row, x|
    row.split("").each_with_index do |type, y|
      if type == "."
      elsif type == "@"
        bot = [x, y]
      else
        sparse_board[[x, y]] = type
      end
    end
  end

  {
    instructions:,
    board: sparse_board,
    bot:
  }
end

def find_movable(board, pos, dir)
  over_pos = add(pos, $d[dir])
  over = board[over_pos]
  if board[pos].nil?
    return []
  end
  if board[pos] == "#"
    return :immovable
  end
  if over.nil?
    [pos]
  elsif over == "#"
    :immovable
  else
    overs = find_movable(board, over_pos, dir)
    return :immovable if overs == :immovable
    [pos, *overs]
  end
end

def print_board(board, (x, y))
  height = board.keys.map { _1[0] }.max + 1
  width = board.keys.map { _1[1] }.max + 1
  board_str = height.times.map { "." * width }
  board.each do |(x, y), kind|
    if kind.is_a? Box
      if kind.p1 == [x, y]
        board_str[x][y] = "["
      else
        board_str[x][y] = "]"
      end
    else
      board_str[x][y] = kind
    end
  end
  if board_str[x][y] == "."
    board_str[x][y] = "@"
  else
    board_str[x][y] = "X"
  end
  puts board_str.join("\n")
end

def one(input)
  parse_input(input) => { board:, bot:, instructions: }
  board = board
  bot = bot

  instructions.split("").each do |instruction|
    over = add(bot, $d[instruction])
    overs = find_movable(board, over, instruction)
    if overs == :immovable
      next
    end

    if last = overs.last
      board[add(last, $d[instruction])] = "O"
    end
    if first = overs.first
      board.delete(first)
    end

    bot = over
  end

  board.sum do |(x, y), value|
    if value == "O"
      100 * x + y
    else
      0
    end
  end
end

class Box
  attr_accessor :p1, :p2

  def initialize(p1, p2)
    @p1 = p1
    @p2 = p2
  end

  # Check if this box is movable in a given direction
  def blocked(board, dir)
    neighbour_boxes = []

    neighbours(dir).each do |pos|
      box = board[pos]
      next if box.nil?
      throw :blocked if box == "#"
      next if neighbour_boxes.include? box
      neighbour_boxes << box
    end


    neighbour_boxes.each do |box|
      box.blocked(board, dir)
    end
  end

  # Nudge a box in a given direction
  def nudge(board, dir)
    neighbour_boxes = []

    neighbours(dir).each do |pos|
      box = board[pos]
      next if box.nil?
      next if neighbour_boxes.include? box
      neighbour_boxes << box
    end


    neighbour_boxes.each do |box|
      box.nudge(board, dir)
    end

    move(board, dir)
  end

  def move(board, dir)
    case dir
    when ">"
      new_p2 = add(@p2, $d[dir])
      board.delete(@p1)
      @p1 = @p2
      @p2 = new_p2
      board[@p2] = self
    when "<"
      new_p1 = add(@p1, $d[dir])
      board.delete(@p2)
      @p2 = @p1
      @p1 = new_p1
      board[@p1] = self
    when "^", "v"
      new_p1 = add(@p1, $d[dir])
      new_p2 = add(@p2, $d[dir])
      board.delete(@p1)
      board.delete(@p2)
      @p1 = new_p1
      @p2 = new_p2
      board[@p1] = self
      board[@p2] = self
    end
  end

  def neighbours(dir)
    case dir
    when ">"
      [add(@p2, $d[dir])]
    when "<"
      [add(@p1, $d[dir])]
    when "^", "v"
      [add(@p2, $d[dir]), add(@p1, $d[dir])]
    end
  end

  def gps
    x, y = @p1
    100 * x + y
  end
end

def parse_input2(input)
  board, instructions = input.split("\n\n")

  instructions = instructions.split.join("")

  sparse_board = {}
  bot = nil
  board.split.each_with_index do |row, x|
    row.split("").each_with_index do |type, y|
      ay = y * 2
      by = ay + 1

      if type == "."
      elsif type == "@"
        bot = [x, ay]
      elsif type == "#"
        sparse_board[[x, ay]] = type
        sparse_board[[x, by]] = type
      else type == "O"
        box = Box.new([x, ay], [x, by])
        sparse_board[[x, ay]] = box
        sparse_board[[x, by]] = box
      end
    end
  end

  {
    instructions:,
    board: sparse_board,
    bot:
  }
end

def two(input)
  parse_input2(input) => { board:, bot:, instructions: }
  board = board
  bot = bot

  instructions.split("").each_with_index do |instruction, i|
    over_pos = add(bot, $d[instruction])
    over = board[over_pos]

    if over.nil?
      bot = over_pos
      next
    end

    if over == "#"
      next
    end

    catch :blocked do
      over.blocked(board, instruction)
      over.nudge(board, instruction)
      bot = over_pos
    end
  end

  count = 0
  board.each do |pos, kind|
    if kind.is_a? Box
      if pos == kind.p1
        count += kind.gps
      end
    end
  end
  count
end

puts "test:"

puts "p1.a:"
puts one("########
#..O.O.#
##@.O..#
#...O..#
#.#.O..#
#...O..#
#......#
########

<^^>>>vv<v>>v<<")
puts "p1.orig:"
puts one(test_input)
puts "p1.c:"
puts two("#######
#...#.#
#.....#
#..OO@#
#..O..#
#.....#
#######

<vv<<^^<<^^")

puts "p2.a:"
puts two("#######
#.....#
#.O#..#
#..O@.#
#.....#
#######

<v<<^")

puts "p2.b:"
puts two("######
#....#
#.O..#
#.OO@#
#.O..#
#....#
######

<vv<<^")

puts "p2.c:"
puts two("#######
#.....#
#.#O..#
#..O@.#
#.....#
#######

<v<^")

puts "p2.d:"
puts two("#######
#.....#
#.OO@.#
#.....#
#######

<<")

puts "p2.e:"
puts two("#######
#.....#
#.O.O@#
#..O..#
#..O..#
#.....#
#######

<v<<>vv<^^")

puts "p2.f:"
puts two("#######
#.....#
#.#O..#
#..O@.#
#.....#
#######

<v<^")

puts "p2.orig:"
puts two(test_input)
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
