class ImpossiblePuzzle
  def initialize
    @others = {
      1 => [2, 3, 4],
      2 => [1, 3, 4],
      3 => [2, 1, 4],
      4 => [2, 3, 1],
    }
  end

  def run
    results = []
    (1000..9999).each do |t|
      digits = t.to_s.split("").map(&:to_i)
      valid = true

      # Using the letter X in order to prevent the rule to be applied to the
      # same digit twice
      # valid &&= one_is_correct(digits, [3, 4, 1, "X"])
      # valid &&= one_is_correct(digits, [4, 2, "X", 7])
      # valid &&= has_in_others(digits, [4, 8, 1, 7])
      # valid &&= has_in_others(digits, ["X", 2, 7, 1])
      valid &&= one_is_correct(digits, [3, 4, 1, 7])
      valid &&= one_is_correct(digits, [4, 2, 1, 7])
      valid &&= has_in_others(digits, [4, 8, 1, 7])
      valid &&= has_in_others(digits, [4, 2, 7, 1])

      if valid
        results << t
      end
    end

    results
  end

  def has_in_others(digits, targets)
    targets.each_with_index do |target, index|
      @others[index + 1].each do |position|
        if digits[position - 1] == target
          puts "hi"
          return true
        end
      end
    end

    false
  end

  def one_is_correct(digits, targets)
    digits.each_with_index do |digit, index|
      if targets[index] == digit
          puts "hi"
        return true
      end
    end

    false
  end
end

results = ImpossiblePuzzle.new.run
puts results
puts results.size
