require "../lib/main.rb"
require "ruby-cbc"

input = input_lines("aoc-input.txt")
test_input =  input_lines("aoc-test.txt")

def one(input)
  i = input.map do |l|
    a = l.split(" ")
    target = a.first[1..-2]
    jolts = a.last[1..-2].split(",").map(&:to_i)
    buttons = a[1..-2].map { |b| b[1..-2].split(",").map(&:to_i) }

    [target, buttons, jolts]
  end

  i.sum do |i|
    one_i(i[0], i[1])
  end
end

def two(input)
  i = input.map do |l|
    a = l.split(" ")
    target = a.first[1..-2]
    jolts = a.last[1..-2].split(",").map(&:to_i)
    buttons = a[1..-2].map { |b| b[1..-2].split(",").map(&:to_i) }

    [target, buttons, jolts]
  end

  i.sum do |i|
    model = Cbc::Model::new
    # jolt_variables = model.int_var_array(i[2].size, 0..Cbc::INF, names: i[2].size.times.map { "j#{_1}"})
    button_press_counts = model.int_var_array(i[1].size, 0..Cbc::INF, names: i[1].size.times.map { "press#{_1}"})

    # for each button press,
    # press_count == jolt A + jolt B...
    # i[1].each_with_index do |b, i|
    #   sum = if b.size == 1
    #     jolt_variables[b[0]]
    #   else
    #     b.map { jolt_variables[_1] }.sum
    #   end
    #   model.enforce(sum >= button_press_counts[i])
    # end

    # don't over complicate it...
    # each jolt == press_a_count + press_b_count
    i[2].each_with_index do |j, ji|
      presses = []
      i[1].each.with_index do |b, bi|
        if b.include?(ji)
          presses << button_press_counts[bi]
        end
      end
      sum = if presses.size == 1
        presses[0]
      else
        presses.sum
      end
      model.enforce(sum == j)
    end

    # for each jolt target
    # The jolt variable should == the desired final count
    # i[2].each_with_index do |j, i|
    #   model.enforce(jolt_variables[i] == j)
    # end

    # minimize how many times we press a button
    model.minimize(button_press_counts.sum)

    # puts model

    problem = model.to_problem
    problem.solve

    # puts "Optimal?: #{problem.proven_optimal?}"
    # puts "Time limit reached?: #{problem.time_limit_reached?}"
    # puts "Feisable?: #{!problem.proven_infeasible?}"
    # jolt_variables.each_with_index do |j, i|
    #   puts "j#{i} = #{problem.value_of(j)}"
    # end
    # button_press_counts.each_with_index do |b, i|
    #   puts "press#{i} = #{problem.value_of(b)}"
    # end
    button_press_counts.sum { problem.value_of(_1) }
  end
end

def one_i(target, available_buttons)
  x = [["." * target.size, []]]

  depth = 0
  loop do
    depth += 1
    x = x.map do |(current, pressed)|
      available_buttons.reject { pressed.include?(_1) }.map do |b|
        new = current.dup
        b.each do |b|
          if new[b] == "#"
            new[b] = "."
          else
            new[b] = "#"
          end
        end
        if new == target
          return depth
        end
        [new, [*pressed, b]]
      end
    end.flatten(1)
  end
end


puts "test:"
puts one(test_input)
puts two(test_input)
puts "input:"
puts one(input)
puts two(input)
