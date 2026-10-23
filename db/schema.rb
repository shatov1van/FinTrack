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

ActiveRecord::Schema[8.1].define(version: 2026_10_23_121931) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bank_statements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "bank_name"
    t.string "account_mask"
    t.string "file_name"
    t.string "status"
    t.date "period_start"
    t.date "period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bank_statements_on_user_id"
    t.index ["user_id", "bank_name", "account_mask", "period_start", "period_end"], 
            unique: true, 
            name: "index_bank_statements_unique_period"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", null: false
    t.string "color", default: "#000000"
    t.text "keywords"
    t.string "kind", default: "expense", null: false
    t.boolean "is_system", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    
    t.index ["user_id"], name: "index_categories_on_user_id"
    t.index ["kind"], name: "index_categories_on_kind"
  end

  create_table "financial_transactions", force: :cascade do |t|
    t.bigint "bank_statement_id", null: false
    t.bigint "category_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "transaction_type", null: false
    t.date "transaction_date", null: false
    t.string "merchant", null: false
    t.boolean "is_subscription", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_statement_id"], name: "index_financial_transactions_on_bank_statement_id"
    t.index ["category_id"], name: "index_financial_transactions_on_category_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bank_statements", "users"
  add_foreign_key "financial_transactions", "bank_statements"
  add_foreign_key "financial_transactions", "categories"
  add_foreign_key "categories", "users"
end
