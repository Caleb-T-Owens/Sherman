class CreatePuzzleCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :puzzle_completions do |t|
      t.belongs_to :user, foreign_key: { index: true }
      t.belongs_to :puzzle, foreign_key: { index: true }

      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
  end
end
