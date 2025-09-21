class CreateRepositories < ActiveRecord::Migration[8.0]
  def change
    create_table :repositories do |t|
      t.text :gh_token
      t.string :owner
      t.string :repo

      t.timestamps
    end
  end
end
