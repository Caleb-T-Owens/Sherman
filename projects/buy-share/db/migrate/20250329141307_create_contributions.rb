class CreateContributions < ActiveRecord::Migration[8.0]
  def change
    create_table :contributions do |t|
      t.integer :amount, null: false, default: 0
      t.references :fund_membership, null: false, foreign_key: true
      t.datetime :last_contributed_at
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    
    add_index :contributions, :amount
    add_index :contributions, :active
  end
end
