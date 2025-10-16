class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :account_type, null: false
      t.references :parent, foreign_key: { to_table: :accounts }, null: true
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :accounts, :code, unique: true
    add_index :accounts, [:account_type, :active]
    add_index :accounts, :parent_id
  end
end
