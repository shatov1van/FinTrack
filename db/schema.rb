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

ActiveRecord::Schema[8.1].define(version: 2026_10_30_153100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    t.index ["record_type", "record_id", "name"], name: "index_active_storage_attachments_lookup"
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "bank_statements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "bank_name"
    t.string "file_name"
    t.string "status"
    t.date "period_start"
    t.date "period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "account_mask"
    t.string "file_digest"
    t.string "source_format"
    t.text "error_message"
    t.boolean "archived", default: false, null: false
    t.integer "imported_count", default: 0, null: false
    t.integer "duplicate_count", default: 0, null: false
    t.index ["user_id", "bank_name", "account_mask", "period_start", "period_end"], name: "index_bank_statements_unique_period", unique: true
    t.index ["user_id", "file_digest"], name: "index_bank_statements_on_user_id_and_file_digest", unique: true
    t.index ["user_id"], name: "index_bank_statements_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.text "keywords"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "kind", default: "expense", null: false
    t.boolean "is_system", default: false, null: false
    t.index ["kind"], name: "index_categories_on_kind"
    t.index ["user_id"], name: "index_categories_on_user_id"
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
    t.index ["bank_statement_id", "transaction_date", "amount", "merchant"], name: "index_financial_transactions_on_statement_and_identity", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bank_statements", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "financial_transactions", "bank_statements"
  add_foreign_key "financial_transactions", "categories"
end
