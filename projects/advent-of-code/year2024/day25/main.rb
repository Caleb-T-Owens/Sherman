input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

def parse_input(input)
  keys = []
  locks = []
  input.split("\n\n").each do |obj|
    lines = obj.lines(chomp: true)
    if lines.first == "#####"
      locks << lines[1..].map { _1.split("") }.transpose.map { _1.select { |a| a == "#" }.size }
    else
      keys << lines[...lines.size].map { _1.split("") }.transpose.map { _1.select { |a| a == "#" }.size - 1 }
    end
  end

  return locks, keys
end

def lfk(lock, key)
  lock.zip(key).all? { |(a, b)| (a + b) <= 5 }
end

def one(input)
  locks, keys = parse_input(input)
  count = 0
  locks.each do |lock|
    keys.each do |key|
      if lfk(lock, key)
        count += 1
      end
    end
  end
  count
end

puts "test:"
puts "p1:"
puts one(test_input)
puts "input:"
puts "p1:"
puts one(input)
