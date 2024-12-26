require "securerandom"

input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def around(x, y)
  [
    [x - 1, y],
    [x + 1, y],
    [x, y - 1],
    [x, y + 1]
  ]
end

def find_region(letter, x, y, squares)
  out = [[x, y]]

  around(x, y).each do |a, b|
    if squares[[a, b]] == letter
      squares[[a, b]] = false

      out.push(*find_region(letter, a, b, squares))
    end
  end

  out
end

def find_regions(input)
  squares = {}

  input.each_with_index do |row, x|
    row.split("").each_with_index do |letter, y|
      squares[[x, y]] = letter
    end
  end

  regions = []

  squares.each do |(x, y), square|
    if square
      positions = find_region(square, x, y, squares)
      positions = positions.map { [_1, true] }.to_h

      regions << {
        positions:
      }
    end
  end

  regions
end

def one(input)
  regions = find_regions(input)

  regions.sum do |region|
    edges = region[:positions].keys.sum do |(x, y)|
      around(x, y).sum do |x, y|
        if region[:positions][[x, y]]
          0
        else
          1
        end
      end
    end

    edges * region[:positions].size
  end
end

def two(input)
  regions = find_regions(input)

  regions.sum do |region|
    ea = []
    eb = []
    ec = []
    ed = []
    edges = region[:positions].keys.each do |(x, y)|
      if !region[:positions][[x - 1, y]]
        q = ea.find { _1.include?([x - 1, y - 1])}
        r = ea.find { _1.include?([x - 1, y + 1])}

        if q
          q << [x - 1, y]

          if r
            ea.delete(r)
            q.push(*r)
          end
        elsif r
          r << [x - 1, y]
        else
          ea << [[x - 1, y]]
        end
      end
      if !region[:positions][[x + 1, y]]
        q = eb.find { _1.include?([x + 1, y - 1])}
        r = eb.find { _1.include?([x + 1, y + 1])}

        if q
          q << [x + 1, y]

          if r
            eb.delete(r)
            q.push(*r)
          end
        elsif r
          r << [x + 1, y]
        else
          eb << [[x + 1, y]]
        end
      end
      if !region[:positions][[x, y - 1]]
        q = ec.find { _1.include?([x - 1, y - 1])}
        r = ec.find { _1.include?([x + 1, y - 1])}

        if q
          q << [x, y - 1]

          if r
            ec.delete(r)
            q.push(*r)
          end
        elsif r
          r << [x, y - 1]
        else
          ec << [[x, y - 1]]
        end
      end
      if !region[:positions][[x, y + 1]]
        q = ed.find { _1.include?([x - 1, y + 1])}
        r = ed.find { _1.include?([x + 1, y + 1])}

        if q
          q << [x, y + 1]

          if r
            ed.delete(r)
            q.push(*r)
          end
        elsif r
          r << [x, y + 1]
        else
          ed << [[x, y + 1]]
        end
      end
    end

    (ea.size + eb.size + ec.size + ed.size) * region[:positions].size
  end
end

puts "test:"
puts "p1:"
puts one(test_input)
puts "p2:"
puts two(test_input)
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
