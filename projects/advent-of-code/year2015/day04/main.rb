require "digest"

input = File.read("aoc-input.txt", chomp: true).chomp
test_input =  File.read("aoc-test.txt", chomp: true).chomp

def one(input)
  magic = 0
  loop do
    hash = Digest::MD5.hexdigest(input + magic.to_s)
    break if hash.start_with? "00000"
    magic += 1
  end
  magic
end

def two(input)
  magic = 0
  loop do
    hash = Digest::MD5.hexdigest(input + magic.to_s)
    break if hash.start_with? "000000"
    magic += 1
  end
  magic
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
