input = File.readlines("aoc-input.txt", chomp: true)
test_input = File.readlines("aoc-test.txt", chomp: true)

WORDS = %w(AND OR LSHIFT RSHIFT)
MASK = 0xFFFF

def one(input)
  regs = {}

  loop do
    break if input.empty?

    input.each do |line|
      rest, out = line.split(" -> ")
      if word = WORDS.find { rest.include? _1 }
        a, b = rest.split(" #{word} ")

        av = /\d+/.match?(a) ? a.to_i : regs[a]
        next if av.nil?

        case word
        when "AND"
          bv = /\d+/.match?(b) ? b.to_i : regs[b]
          next if bv.nil?
          regs[out] = av & bv
        when "OR"
          bv = /\d+/.match?(b) ? b.to_i : regs[b]
          next if bv.nil?
          regs[out] = av | bv
        when "LSHIFT"
          bv = b.to_i
          regs[out] = (av << bv) & MASK
        when "RSHIFT"
          bv = b.to_i
          regs[out] = av >> bv
        end
      elsif rest.include? "NOT"
        a = rest[4..]
        av = /\d+/.match?(a) ? a.to_i : regs[a]
        next if av.nil?

        regs[out] = av ^ MASK
      else
        av = /\d+/.match?(rest) ? rest.to_i : regs[rest]
        next if av.nil?

        regs[out] = av
      end

      input.delete(line)
    end
  end

  regs
end

def two(input)
  a = one(input.dup)["a"]

  input.delete_if { /-> b$/.match? _1 }
  input.push("#{a} -> b")

  one(input)["a"]
end

puts "test:"
puts one(test_input)
# puts two(test_input)
puts "input:"
puts one(input.dup)["a"]
puts two(input)
