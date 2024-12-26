input = File.read("aoc-input.txt", chomp: true)
test_input =  File.read("aoc-test.txt", chomp: true)

class Computer
  attr_accessor :a, :b, :c

  def initialize(a, b, c, instructions)
    @a = a
    @b = b
    @c = c
    @instructions = instructions
    @pc = 0
    @output = []
    @halted = false
  end

  def run
    until @halted
      if opcode.nil?
        @halted = true
        break
      end

      apc = true

      case opcode
      when 0
        @a = (@a / (2 ** oprand_combo)).floor
      when 1
        @b = @b ^ oprand_lit
      when 2
        @b = oprand_combo % 8
      when 3
        unless @a == 0
          @pc = oprand_lit
          apc = false
        end
      when 4
        @b = @b ^ @c
      when 5
        @output << oprand_combo % 8
      when 6
        @b = (@a / (2 ** oprand_combo)).floor
      when 7
        @c = (@a / (2 ** oprand_combo)).floor
      else
        raise "oopsy doopsy"
      end

      advance_pc if apc
    end
  end

  def advance_pc
    @pc += 2
  end

  def opcode
    @instructions[@pc]
  end

  def oprand_lit
    @instructions[@pc + 1]
  end

  def oprand_combo
    return oprand_lit if oprand_lit <= 3
    if oprand_lit == 4
      return @a
    elsif oprand_lit == 5
      return @b
    elsif oprand_lit == 6
      return @c
    else
      raise "oops!"
    end
  end

  def output
    @output.map(&:to_s).join(",")
  end

  def outarr
    @output
  end

  def instructions
    @instructions.map(&:to_s).join(",")
  end

  def iarr
    @instructions
  end

  def reset
    @output = []
    @pc = 0
    @halted = false
  end
end

def parse_input(input)
  regs, instrs = input.split("\n\n")
  a, b, c = regs.lines.map { _1.split(": ").last.to_i }

  instructions = instrs.split(": ").last.split(",").map(&:to_i)

  Computer.new(a, b, c, instructions)
end

def one(input)
  computer = parse_input(input)

  computer.run
  computer.output
end

def two(input)
  computer = parse_input(input)
  instructions = computer.instructions

  a = 0
  index = computer.iarr.size - 1
  loop do
    c1 = computer.dup
    c1.reset
    c1.a = a
    c1.run

    while c1.outarr.size < c1.iarr.size
      c1.outarr << 1000
    end

    if c1.outarr[index] == c1.iarr[index]
      if index == 0
        break
      else
        index -= 1
      end
    else
      a += 8 ** index
    end
  end

  a
end

puts "test:"
puts "p1:"
puts one(test_input)
puts "p2:"
puts two("Register A: 2024
Register B: 0
Register C: 0

Program: 0,3,5,4,3,0")
puts "input:"
puts "p1:"
puts one(input)
puts "p2:"
puts two(input)
