class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :content, null: false
      t.belongs_to :user, null: false, foreign_key: true
      t.integer :likes_count, default: 0, null: false

      t.timestamps
    end
  end
end
