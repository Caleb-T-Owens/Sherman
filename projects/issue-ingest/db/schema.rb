# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_21_224845) do
  create_table "issues", force: :cascade do |t|
    t.integer "repository_id", null: false
    t.integer "number", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.json "tags", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id", "number"], name: "index_issues_on_repository_id_and_number", unique: true
    t.index ["repository_id"], name: "index_issues_on_repository_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.text "gh_token"
    t.string "owner"
    t.string "repo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_repositories", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "repository_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id"], name: "index_user_repositories_on_repository_id"
    t.index ["user_id"], name: "index_user_repositories_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "issues", "repositories"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_repositories", "repositories"
  add_foreign_key "user_repositories", "users"
end
