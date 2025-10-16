class CreateEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :entries do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :entry_type, null: false
      t.text :memo

      t.timestamps
    end

    add_index :entries, [:transaction_id, :account_id]
    add_index :entries, [:account_id, :transaction_id]

    # Ensure amount is always positive
    add_check_constraint :entries, "amount > 0", name: "entries_amount_positive"

    # Ensure entry_type is either debit or credit
    add_check_constraint :entries, "entry_type IN ('debit', 'credit')", name: "entries_type_valid"
  end
end
