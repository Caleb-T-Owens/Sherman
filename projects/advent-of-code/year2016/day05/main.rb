require "digest"

input = File.readlines("aoc-input.txt", chomp: true)
test_input =  File.readlines("aoc-test.txt", chomp: true)

def one(input)
  input = input.first
  i = 0
  password = ""
  loop do
    s = Digest::MD5.hexdigest(input + i.to_s)
    if s[0..4] == "00000"
      password = password + s[5]
      if password.size == 8
        break
      end
    end
    i+=1
  end

  password
end

def two(input)
  input = input.first
  i = 0
  password = "        "
  loop do
    s = Digest::MD5.hexdigest(input + i.to_s)
    if s[0..4] == "00000" && (0..7).include?(s[5].to_i(16))
      pp [password, s, i]
      if password[s[5].to_i] == " "
        password[s[5].to_i] = s[6]
        if !password.include?(" ")
          break
        end
      end
    end
    i+=1
  end

  password
end

puts "test:"
# puts one(test_input)
puts two(test_input)
puts "input:"
# puts one(input)
puts two(input)
