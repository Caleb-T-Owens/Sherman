require "parallel"

input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  Parallel.map(input, in_processes: 16) do |i|
    target, tail = i.split(": ")
    target = target.to_i
    tail = tail.split(" ").map(&:to_i)

    if addmul(target, tail[0], tail[1..]) == :solved
      target
    else
      0
    end
  end.sum
end

def addmul(target, current, digets)
  if digets.size == 0
    if current == target
      return :solved
    else
      return :unsolved
    end
  end

  a = current + digets[0]
  ax = addmul(target, a, digets[1..])
  if ax == :solved
    return :solved
  end

  b = current * digets[0]
  bx = addmul(target, b, digets[1..])
  if bx == :solved
    return :solved
  end

  :unsolved
end

def two(input)
  Parallel.map(input, in_processes: 16) do |i|
    target, tail = i.split(": ")
    target = target.to_i
    tail = tail.split(" ").map(&:to_i)

    if addmulconc(target, tail[0], tail[1..]) == :solved
      target
    else
      0
    end
  end.sum
end

def addmulconc(target, current, digets)
  if digets.size == 0
    if current == target
      return :solved
    else
      return :unsolved
    end
  end

  a = current + digets[0]
  ax = addmulconc(target, a, digets[1..])
  if ax == :solved
    return :solved
  end

  b = current * digets[0]
  bx = addmulconc(target, b, digets[1..])
  if bx == :solved
    return :solved
  end

  c = (current.to_s + digets[0].to_s).to_i
  cx = addmulconc(target, c, digets[1..])
  if cx == :solved
    return :solved
  end

  :unsolved
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
