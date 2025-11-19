class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :description

      t.references :source, foreign_key: { to_table: :accounts }
      t.references :destination, foreign_key: { to_table: :accounts }

      t.timestamps
    end
  end
end
