def input_lines(file)
  File.readlines(file, chomp: true)
end

def input_file(file)
  File.read(file).chomp
end