# == Schema Information
#
# Table name: puzzles
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  url        :string           not null
#  series     :string
#  site_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_puzzles_on_site_id  (site_id)
#

class Puzzle < ApplicationRecord
  belongs_to :site
  has_many :puzzle_completions, dependent: :destroy

  def other_users_completions(current_user)
    puzzle_completions.reject { _1.user_id == current_user&.id }.sort_by(&:created_at) # where.not(user: current_user).order(:created_at)
  end

  def current_user_completion(current_user)
    puzzle_completions.find { _1.user_id == current_user&.id }
  end
end
