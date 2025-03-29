class CreateFundMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :fund_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :fund, null: false, foreign_key: true
      t.string :role

      t.timestamps
    end
    add_index :fund_memberships, [:user_id, :fund_id], unique: true
  end
end
