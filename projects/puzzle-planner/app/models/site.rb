# == Schema Information
#
# Table name: sites
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Site < ApplicationRecord
  ADVENT_OF_CODE = "Advent of Code"
  PROJECT_EULER = "Project Euler"
  SPECIAL = [ ADVENT_OF_CODE, PROJECT_EULER ]

  has_many :puzzles

  validates_uniqueness_of :name

  def protected?
    name.in? Site::SPECIAL
  end

  def grouped_puzzles
    puzzles
      .group_by(&:series)
      .to_a
      .sort_by { _1.first.to_s }
  end
end
