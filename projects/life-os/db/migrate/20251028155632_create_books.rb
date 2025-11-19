class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.belongs_to :user, foreign_key: true

      t.string :name

      t.timestamps
    end
  end
end
