require "../lib/main.rb"
require "enumerator"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  mutable_i = input.map { _1.dup }

  split_count = 0

  mutable_i.each_cons(2) do |(a, b)|
    a.chars.each_with_index do |c, i|
      if c == "S" || c == "|"
        if b[i] == "^"
          split_count += 1
          b[i-1] = "|"
          b[i+1] = "|"
        else
          b[i] = "|"
        end
      end
    end
  end

  split_count
end

def two(input)
  mutable_i = input.map { _1.chars }

  mutable_i.each_cons(2) do |(a, b)|
    a.each_with_index do |c, i|
      sum = if c == "S" || c == "|"
        1
      elsif c.is_a?(Numeric)
        c
      else
        nil
      end

      if sum
        if b[i] == "^"
          b[i-1] = sum + n_or_z(b[i-1])
          b[i+1] = sum + n_or_z(b[i+1])
        else
          b[i] =  sum + n_or_z(b[i])
        end
      end
    end
  end

  mutable_i.last.sum { _1.is_a?(Numeric) ? _1 : 0 }
end

def n_or_z(f)
  if f.is_a?(Numeric)
    f
  else
    0
  end
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
