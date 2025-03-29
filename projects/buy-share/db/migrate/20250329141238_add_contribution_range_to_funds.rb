class AddContributionRangeToFunds < ActiveRecord::Migration[8.0]
  def change
    add_column :funds, :min_contribution, :integer, null: false, default: 0
    add_column :funds, :max_contribution, :integer, null: false, default: 100000  # Default max $1000
  end
end
