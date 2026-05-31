input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  out = 0
  input.each do |line|
    total_len = line.size
    inner = line[1..-2]
    len = 0

    context = :none
    byte_count = 0
    inner.chars do |char|
      if context == :none
        if char == "\\"
          context = :forward
        else
          len += 1
        end
      elsif context == :forward
        if ["\\", "\""].include? char
          len += 1
          context = :none
        elsif char == "x"
          context = :byte
          byte_count = 1
        else
          # Syntax error?
          len += 2
        end
      elsif context == :byte
        if byte_count == 2
          len += 1
          context = :none
        else
          byte_count += 1
        end
      end
    end

    out += total_len - len
  end

  out
end

def two(input)
  out = 0
  input.each do |line|
    total_len = line.size
    len = 2

    line.chars do |char|
      len += 1
      if ["\"", "\\"].include? char
        len += 1
      end
    end

    out += len - total_len
  end

  out
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
