input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def parse_instrs(i)
  i.map do |instr|
    out = {}

    stuff, outreg = instr.split(" -> ")

    out[:outreg] = outreg

    if stuff.include?("OR")
      out[:instr] = :or
      a, b = stuff.split(" OR ")
      out[:ina] = a
      out[:inb] = b
    elsif stuff.include?("AND")
      out[:instr] = :and
      a, b = stuff.split(" AND ")
      out[:ina] = a
      out[:inb] = b
    elsif stuff.include?("LSHIFT")
      out[:instr] = :lshift
      a, b = stuff.split(" LSHIFT ")
      out[:ina] = a
      out[:inb] = b
    elsif stuff.include?("RSHIFT")
      out[:instr] = :rshift
      a, b = stuff.split(" RSHIFT ")
      out[:ina] = a
      out[:inb] = b
    elsif stuff.include?("NOT")
      out[:instr] = :not
      a = stuff.split("NOT ")[1]
      out[:ina] = a
    else # Assignemt
      out[:instr] = :assignment
      out[:in] = stuff
    end

    out
  end
end

def access_value(memory, operand)
  if /\d+/.match?(operand)
    operand.to_i
  else
    memory[operand] || 0
  end
end

def clamp(value)
  [[value, 65535].min, 0].max
end

def one(input)
  memory = {}
  parsed_input = parse_instrs(input)

  parsed_input.each do |instr|
    if instr[:instr] == :or
      memory[instr[:outreg]] = clamp(access_value(memory, instr[:ina]) | access_value(memory, instr[:inb]))
    elsif instr[:instr] == :and
      memory[instr[:outreg]] = access_value(memory, instr[:ina]) & access_value(memory, instr[:inb]))
    elsif instr[:instr] == :lshift
      memory[instr[:outreg]] = access_value(memory, instr[:ina]) << access_value(memory, instr[:inb])
    elsif instr[:instr] == :and
      memory[instr[:outreg]] = access_value(memory, instr[:ina]) >> access_value(memory, instr[:inb])
    elsif instr[:instr] == :not
      memory[instr[:outreg]] = access_value(memory, instr[:ina]) ^ 0
    else
      memory[instr[:outreg]] = access_value(memory, instr[:ina])
    end
  end
memory["a"]
end

def two(input)
  input.size
end

puts "input:"
puts one(input)
puts two(input)
