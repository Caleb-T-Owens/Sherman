require "json"

input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

def one(input)
  out = []
  input.split("").each_with_index.map do |a, index|
    if index % 2 == 0
      out.push(*([index / 2] * a.to_i))
    else
      out.push(*([ "." ] * a.to_i))
    end
  end

  out.each_with_index do |a, index|
    if a == "."
      x = out.pop
      until x != "."
        x = out.pop
      end
      out[index] = x
    end
  end

  out.each_with_index.sum do |a, i|
    a.to_i * i
  end
end

def two(input)
  out = []
  input.split("").each_with_index.map do |a, index|
    if index % 2 == 0
      out.push({ size: a.to_i, id: (index / 2) })
    else
      out.push({ size: a.to_i, id: :space })
    end
  end

  out.reject! { _1[:size] == 0 }

  out.map(&:dup).reverse.each do |a|
    if a[:id] != :space
      # For each file, starting from the largest to the smallest
      ai = out.find_index { _1 == a }
      # Grab reference to a in the output array
      a = out[ai]

      # Find the first available space
      b, bi = out.each_with_index.find { |(b, bi)| bi < ai && b[:id] == :space && b[:size] >= a[:size] }
      # If there is no available space for the file, it can't be moved
      next if b.nil?

      if b[:size] == a[:size]
        # If the available space is the same size, swap the IDs
        b[:id] = a[:id]
        a[:id] = :space
      else
        # If the file is smaller than the space
        # Place a new entry before the space
        out.insert(bi, { size: a[:size], id: a[:id] })
        # Convert the old file into space
        a[:id] = :space
        # Decrease the space we've inserted into
        b[:size] -= a[:size]
      end

      # Flatten out spaces
      loop do
        previous = out.hash

        out.each_with_index.each_cons(2) do |(a, ai), (b, bi)|
          if a[:id] == :space && b[:id] == :space
            out.delete_at(bi)
            a[:size] += b[:size]
            break
          end
        end

        break if previous == out.hash
      end
    end
  end


  # Convert into regular representation
  outstr = []
  out.each do |a|
    if a[:id] == :space
      outstr.push(*(["."] * a[:size]))
    else
      outstr.push(*([a[:id]] * a[:size]))
    end
  end

  outstr.each_with_index.sum do |a, i|
    next 0 if a == "."
    a.to_i * i
  end
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
