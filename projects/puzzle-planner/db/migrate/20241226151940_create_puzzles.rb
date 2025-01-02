class CreatePuzzles < ActiveRecord::Migration[8.0]
  def change
    create_table :puzzles do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :series
      t.belongs_to :site, foreign_key: { index: true }, null: false
      t.timestamps
    end
  end
end
