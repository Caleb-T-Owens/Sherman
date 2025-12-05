class CreateRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :repositories do |t|
      t.string :owner, null: false
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true
      t.references :token, null: true, foreign_key: true

      t.timestamps
    end

    add_index :repositories, [:user_id, :owner, :name], unique: true
  end
end
