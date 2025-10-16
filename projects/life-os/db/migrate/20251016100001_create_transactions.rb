class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.date :date, null: false
      t.text :description, null: false
      t.string :status, default: 'draft', null: false
      t.datetime :posted_at
      t.string :reference
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :transactions, :status
    add_index :transactions, :date
    add_index :transactions, [:user_id, :date]
    add_index :transactions, [:user_id, :status]
  end
end
