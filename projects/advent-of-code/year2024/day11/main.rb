input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

def one(input)
  solve(input)
end

def two(input)
  solve(input, 75)
end

def solve(input, rounds = 25)
  current = {}

  input.split.each do |entry|
    current[entry.to_i] ||= 0
    current[entry.to_i] += 1
  end

  rounds.times do
    next_round = {}

    current.each do |marking, count|
      if marking == 0
        next_round[1] ||= 0
        next_round[1] += count
      elsif marking.to_s.size % 2 == 0
        marking_string = marking.to_s
        a = marking_string[...(marking_string.size / 2)].to_i
        b = marking_string[(marking_string.size / 2)..].to_i

        next_round[a] ||= 0
        next_round[b] ||= 0
        next_round[a] += count
        next_round[b] += count
      else
        next_marking = marking * 2024
        next_round[next_marking] ||= 0
        next_round[next_marking] += count
      end
    end

    current = next_round
  end

  current.sum { |(a, b)| b }
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
