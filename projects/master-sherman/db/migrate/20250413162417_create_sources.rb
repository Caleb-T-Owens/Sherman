class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :git_url, null: false
      t.datetime :last_fetched_at

      t.timestamps
    end
    
    add_index :sources, :name, unique: true
  end
end
