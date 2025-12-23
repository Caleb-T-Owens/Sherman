require "../lib/main.rb"
require "enumerator"

input = input_lines("aoc-input.txt")
test_input2 = input_lines("aoc-test2.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  i = input.map { _1.split(/[\[\]]/).each.with_index.partition { |a, i| i % 2 == 0 }.map { |a| a.map { |b| b[0] } } }
  sum = 0
  i.each do |(non_bracket, bracket)|
    if non_bracket.any? { contains_abba(_1) } && !bracket.any? { contains_abba(_1) }
      sum += 1
    end
  end
  sum
end

def contains_abba(str)
  str.chars.each_cons(4) do |a|
    if a[0] == a[3] && a[1] == a[2] && a[0] != a[1]
      return true
    end
  end
  false
end

def two(input)
  i = input.map { _1.split(/[\[\]]/).each.with_index.partition { |a, i| i % 2 == 0 }.map { |a| a.map { |b| b[0] } } }
  sum = 0
  i.each do |(non_bracket, bracket)|
    abas = bracket.map { |b| b.chars.each_cons(3).select { _1[0] == _1[2] && _1[0] != _1[1] } }.flatten(1)

    if non_bracket.any? { |b| b.chars.each_cons(3).any? { |x| x[0] == x[2] && x[0] != x[1] && abas.any? { |aba| aba[0] == x[1] && aba[1] == x[0] } } }
      sum += 1
    end
  end
  sum
end

puts "test:"
puts one(test_input)
puts two(test_input2)
puts "input:"
puts one(input)
puts two(input)
