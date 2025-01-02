# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

aoc = Site.find_or_create_by!(name: Site::ADVENT_OF_CODE, url: "https://adventofcode.com")
(2015..2024).each do |year|
  (1..25).each do |day|
    Puzzle.find_or_create_by(
      series: "year #{year}",
      name: "day #{day.to_s.rjust(2, "0")} part 1",
      site: aoc,
      url: "https://adventofcode.com/#{year}/day/#{day}"
    )
    Puzzle.find_or_create_by(
      series: "year #{year}",
      name: "day #{day.to_s.rjust(2, "0")} part 2",
      site: aoc,
      url: "https://adventofcode.com/#{year}/day/#{day}"
    )
  end
end

pe = Site.find_or_create_by!(name: Site::PROJECT_EULER, url: "https://projecteuler.net")
(1..913).each do |number|
  n = (number / 100).floor * 100
  Puzzle.find_or_create_by(
    series: "problems #{n.to_s.rjust(4, "0")} to #{(n + 99).to_s.rjust(4, "0")}",
    name: "problem #{number.to_s.rjust(4, "0")}",
    site: pe,
    url: "https://projecteuler.net/problem=#{number}"
  )
end
