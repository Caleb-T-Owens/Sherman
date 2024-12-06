input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

def one(input)
  head, tail = input.split("\n\n")
  order_rules = head.lines.map { _1.split("|").map(&:to_i) }
  sequences = tail.lines.map { _1.split(",").map(&:to_i) }

  # Select the sequences that match the ordering
  sequences.select { |a|
    order_rules.all? { |b|
      if key_index = a.index(b[0])
        if other_idex = a.index(b[1])
          key_index < other_idex
        else
          true
        end
      else
        true
      end
    }
  }.sum { _1[_1.size / 2] }
end

def two(input)
  head, tail = input.split("\n\n")
  order_rules = head.lines.map { _1.split("|").map(&:to_i) }
  sequences = tail.lines.map { _1.split(",").map(&:to_i) }

  sequences.reject { |a|
    order_rules.all? { |b|
      if key_index = a.index(b[0])
        if other_idex = a.index(b[1])
          key_index < other_idex
        else
          true
        end
      else
        true
      end
    }
  }.map { |a|
    c = a.dup
    old_a = nil

    until old_a == c
      old_a = c.dup
      order_rules.each { |b|
        if key_index = c.index(b[0])
          if other_idex = c.index(b[1])
            if key_index > other_idex
              value = c.delete_at(other_idex)
              c.insert(key_index, value)
            end
          end
        end
      }
    end

    c
  }.sum { _1[_1.size / 2] }
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
