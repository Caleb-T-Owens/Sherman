require "enumerator"

basis_words = File.read("text.txt")

$trigrams = {}
$bigrams = {}
$quadrams = {}

# basis_words.chars.each_cons(2) do |gram|
#   $bigrams[gram] ||= 0
#   $bigrams[gram] += 1
# end

basis_words.chars.each_cons(3) do |gram|
  $trigrams[gram] ||= 0
  $trigrams[gram] += 1
end

basis_words.chars.each_cons(4) do |gram|
  $quadrams[gram] ||= 0
  $quadrams[gram] += 1
end

$trigrams.transform_values! { Math.log(_1) }
$quadrams.transform_values! { Math.log(_1) }

string = "pigmihm drp mhsiama qdmpm mbndq uitl-fmqqml nblfp hrgmp: ltoy, ilfr, prlr, rooy, gryr, tpdr, hiil, arhb. pdm fmuq r sftm qi dml iwh hrgm otq srh yit wile bq itq"

mappings = 1000.times.map { {} }
letters = ("a".."z").to_a

def map_str(m, str)
  out = ""
  str.chars.each do |c|
    found = false
    m.each do |k, v|
      if k == c
        found = true
        out << v
      end
    end
    if !found
      out << c
    end
  end
  out
end

def rank_mappings(ms, string)
  ms.sort_by do |m|
    score = 0
    str = map_str(m, string)
    # str.chars.each_cons(2) do |gram|
    #   score += ($bigrams[gram] || 0) / 4
    # end
    str.chars.each_cons(3) do |gram|
      score += ($trigrams[gram] || 0)
    end
    str.chars.each_cons(4) do |gram|
      score += $quadrams[gram] || 0
    end
    score
  end
end

10000.times do |i|
  puts "Iteration #{i}"
  ranked = rank_mappings(mappings, string)
  best = ranked.last(200)
  very_best = best.last
  str = map_str(very_best, string)
  puts "Current best: #{str}"
  best = [*best, *ranked.sample(300)]

  news = best.map do |m|
    m = m.dup
    rand(15).times do
      if m.size > 5
        k = m.keys.sample
        m.delete k
      end
    end

    rand(15).times do
      if m.keys.size < 26
        from = (letters - m.keys).sample
        to = (letters - m.values).sample
        m[from] = to
      end
    end
    m
  end

  mappings = [*best, *news]
end

bests = rank_mappings(mappings, string).last(3)

bests.each do |m|
  str = map_str(m, string)
  puts "result:"
  puts str
end

