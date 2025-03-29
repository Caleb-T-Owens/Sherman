class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :title, null: false
      t.text :reason
      t.integer :amount, null: false, default: 0
      t.references :user, null: false, foreign_key: true
      t.references :fund, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :transactions, :title
    add_index :transactions, :amount
  end
end
