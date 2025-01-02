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

require "test_helper"

class PuzzleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
