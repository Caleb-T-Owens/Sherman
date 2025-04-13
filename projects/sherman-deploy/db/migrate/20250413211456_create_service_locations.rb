class CreateServiceLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :service_locations do |t|
      t.references :source, null: false, foreign_key: true
      t.string :path
      t.string :name

      t.timestamps
    end
  end
end
