class AddUntimedCompletionToPuzzleCompletion < ActiveRecord::Migration[8.0]
  def change
    add_column :puzzle_completions, :completed_untimed, :boolean
  end
end
