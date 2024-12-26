input = File.read("aoc-input.txt", chomp: true)
test_input = File.read("aoc-test.txt", chomp: true)

def check_valid(patterns, subject)
  patterns.each do |pattern|
    if pattern == subject
      return true
    end

    if subject.start_with? pattern
      found_valid = check_valid(patterns, subject.sub(pattern, ""))
      return true if found_valid
    end
  end

  false
end

def count_valid(patterns, subject, cache)
  cache_entry = cache[subject]
  return cache_entry if cache_entry

  if subject == ""
    cache[subject] = 1
    return 1
  end

  count = 0

  patterns.each do |pattern|
    if subject.start_with? pattern
      shorter_pattern = subject.sub(pattern, "")
      count += count_valid(patterns, shorter_pattern, cache)
    end
  end

  cache[subject] = count
  count
end

def one(input)
  patterns, subjects = input.split("\n\n")
  patterns = patterns.split(", ").sort_by { -_1.size }
  subjects = subjects.lines.map(&:chomp)

  valids = subjects.select do |subject|
    valid = check_valid(patterns, subject)
    valid
  end

  valids.size
end

def two(input)
  patterns, subjects = input.split("\n\n")
  patterns = patterns.split(", ").sort_by { -_1.size }
  subjects = subjects.lines.map(&:chomp)

  valids = subjects.sum do |subject|
    count_valid(patterns, subject, {})
  end

  valids
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
