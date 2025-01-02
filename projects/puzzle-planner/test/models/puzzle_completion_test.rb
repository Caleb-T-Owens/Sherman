# == Schema Information
#
# Table name: puzzle_completions
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  puzzle_id         :integer
#  started_at        :datetime
#  finished_at       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  completed_untimed :boolean
#
# Indexes
#
#  index_puzzle_completions_on_puzzle_id  (puzzle_id)
#  index_puzzle_completions_on_user_id    (user_id)
#

require "test_helper"

class PuzzleCompletionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
