class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.references :repository, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.json :tags, default: []

      t.timestamps
    end

    add_index :issues, [:repository_id, :number], unique: true
  end
end
