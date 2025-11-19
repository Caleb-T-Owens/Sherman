class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.belongs_to :book, foreign_key: true

      t.string :name
      t.string :type

      t.timestamps
    end
  end
end
