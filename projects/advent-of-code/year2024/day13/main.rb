input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

def parse_input(input)
  input.split("\n\n").map do
    a, b, c = _1.split("\n")
    ax, ay = a.split(", ").map { |x| x.split("+").last.to_i }
    bx, by = b.split(", ").map { |x| x.split("+").last.to_i }
    px, py = c.split(", ").map { |x| x.split("=").last.to_i }

    {
      a: [ax, ay],
      b: [bx, by],
      target: [px, py],
    }
  end
end

def one(input)
  input = parse_input(input)
  input.sum do |i|
    i in { a:, b:, target: }
    ax, ay = a
    bx, by = b
    tx, ty = target

    pc = 0
    oc = 100

    candidates = []

    loop do
      # Break if out of bounds
      if oc < 0 || pc > 100
        break
      end

      xsize = pc * ax + oc * bx
      ysize = pc * ay + oc * by

      if xsize == tx && ysize == ty
        candidates << [pc, oc]
      end

      if pc == 100
        pc = 0
        oc -= 1
      else
        pc += 1
      end
    end

    candidates.map { |(x, y)| x * 3 + y }.min || 0
  end
end

# Let's do some algebra this time
def two(input)
  input = parse_input(input)
  input.sum do |i|
    i in { a:, b:, target: }
    ax, ay = a
    bx, by = b
    tx, ty = target
    tx += 10000000000000
    ty += 10000000000000

    det = ax * by - ay * bx
    next 0 if det.zero?

    m = by * tx - bx * ty
    n = ax * ty - ay * tx

    next 0 unless (m % det).zero?
    next 0 unless (n % det).zero?
    m /= det
    n /= det

    m * 3 + n
  end
end

puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
