string = "pigmihm drp mhsiama qdmpm mbndq uitl-fmqqml nblfp hrgmp: ltoy, ilfr, prlr, rooy, gryr, tpdr, hiil, arhb. pdm fmuq r sftm qi dml iwh hrgm otq srh yit wile bq itq"

mapping = {
  "u" => "f",
  "i" => "o",
  "t" => "u",
  "l" => "r",
  "f" => "l",
  "m" => "e",
  "q" => "t",
  "b" => "i",
  "h" => "n", # ?
  "d" => "h",
  "n" => "g",
  "o" => "b", # ?
  "r" => "a",
  "p" => "s",
  "a" => "d",
  "s" => "c",
  "g" => "m",
  "e" => "k"
}

out = ""

string.chars.each do |c|
  found = false
  mapping.each do |k, v|
    if k == c
      found = true
      out << v
    end
  end
  if !found
    out << c
  end
end

puts string
puts out