require "../lib/main.rb"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  input.sum do |l|
    cs = l

    output = ""
    i = 0
    in_marker = false
    current_marker = ""
    loop do
      if i >= cs.size
        break
      end

      if in_marker
        if cs[i] == ")"
          span, times = current_marker.split("x").map(&:to_i)

          output << cs[(1+i)..(i+span)] * times
          i += span + 1

          current_marker = ""
          in_marker = false
          next
        end

        current_marker << cs[i]
        i += 1
        next
      end

      if cs[i] == "("
        in_marker = true
        i += 1
        next
      end

      output << cs[i]
      i += 1
    end

    output.size
  end
end

def two(input)
  input.sum do |l|
    old_dc = l
    dc = l
    loop do
      dc = decompress(dc)
      if dc == old_dc
        break
      end
      old_dc = dc
    end
    dc.size
  end
end

def decompress(cs)
  output = ""
  i = 0
  in_marker = false
  current_marker = ""
  loop do
    if i >= cs.size
      break
    end

    if in_marker
      if cs[i] == ")"
        span, times = current_marker.split("x").map(&:to_i)

        output << cs[(1+i)..(i+span)] * times
        i += span + 1

        current_marker = ""
        in_marker = false
        next
      end

      current_marker << cs[i]
      i += 1
      next
    end

    if cs[i] == "("
      in_marker = true
      i += 1
      next
    end

    output << cs[i]
    i += 1
  end

  output
end

puts "test:"
# puts one(test_input)
puts two(test_input)
puts "input:"
# puts one(input)
puts two(input)
