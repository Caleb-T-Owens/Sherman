class CreateSites < ActiveRecord::Migration[8.0]
  def change
    create_table :sites do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.timestamps
    end
  end
end
