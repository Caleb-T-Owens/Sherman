def input_lines(file)
  File.readlines(file, chomp: true)
end

def input_file(file)
  File.read(file).chomp
end

SIDES = [
  [-1, -1],
  [-1, 0],
  [-1, 1],
  [0, -1],
  [0, 1],
  [1, -1],
  [1, 0],
  [1, 1],
]

CARDINALS = [
  [-1, 0],
  [0, -1],
  [0, 1],
  [1, 0],
]