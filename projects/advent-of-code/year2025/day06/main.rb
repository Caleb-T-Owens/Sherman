require "../lib/main.rb"
require "enumerator"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  input.map { _1.split }.transpose.sum do |l|
    if l[-1] == "+"
      l[..-2].map(&:to_i).sum
    else
      l[..-2].map(&:to_i).inject { _1 * _2 }
    end
  end
end

def two(input)
  problems = [[]]
  number_lines = input[..-2]
  keys = input[-1].chars

  last_op = nil
  keys.each.with_index do |k, i|
    if number_lines.all? { _1[i] == " " } && k == " "
      problems.last << last_op
      problems << []
      next
    end

    if k != " "
      last_op = k
    end

    number = ""

    number_lines.each do |l|
      if l[i] != " "
        number += l[i]
      end
    end

    problems.last << number.to_i
  end
  problems.last << last_op

  problems.sum do |l|
    if l[-1] == "+"
      l[..-2].map(&:to_i).sum
    else
      l[..-2].map(&:to_i).inject { _1 * _2 }
    end
  end
end

puts "test:"
# puts one(test_input)
puts two(test_input)
puts "input:"
# puts one(input)
puts two(input)
