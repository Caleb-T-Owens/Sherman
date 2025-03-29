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

ActiveRecord::Schema[8.0].define(version: 2025_03_29_141307) do
  create_table "contributions", force: :cascade do |t|
    t.integer "amount", default: 0, null: false
    t.integer "fund_membership_id", null: false
    t.datetime "last_contributed_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_contributions_on_active"
    t.index ["amount"], name: "index_contributions_on_amount"
    t.index ["fund_membership_id"], name: "index_contributions_on_fund_membership_id"
  end

  create_table "fund_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "fund_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fund_id"], name: "index_fund_memberships_on_fund_id"
    t.index ["user_id", "fund_id"], name: "index_fund_memberships_on_user_id_and_fund_id", unique: true
    t.index ["user_id"], name: "index_fund_memberships_on_user_id"
  end

  create_table "funds", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "min_contribution", default: 0, null: false
    t.integer "max_contribution", default: 100000, null: false
    t.index ["name"], name: "index_funds_on_name"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "title", null: false
    t.text "reason"
    t.integer "amount", default: 0, null: false
    t.integer "user_id", null: false
    t.integer "fund_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amount"], name: "index_transactions_on_amount"
    t.index ["fund_id", "created_at"], name: "index_transactions_on_fund_id_and_created_at"
    t.index ["fund_id"], name: "index_transactions_on_fund_id"
    t.index ["title"], name: "index_transactions_on_title"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
  end

  add_foreign_key "contributions", "fund_memberships"
  add_foreign_key "fund_memberships", "funds"
  add_foreign_key "fund_memberships", "users"
  add_foreign_key "transactions", "funds"
  add_foreign_key "transactions", "users"
end
