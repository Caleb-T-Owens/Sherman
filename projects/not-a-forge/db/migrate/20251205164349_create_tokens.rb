class CreateTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :tokens do |t|
      t.string :name, null: false
      t.text :token, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :tokens, [:user_id, :name], unique: true
  end
end
