class CreateFunds < ActiveRecord::Migration[8.0]
  def change
    create_table :funds do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
    add_index :funds, :name
  end
end
