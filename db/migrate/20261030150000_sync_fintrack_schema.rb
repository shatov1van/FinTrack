class SyncFintrackSchema < ActiveRecord::Migration[8.1]
  def change
    add_column :bank_statements, :account_mask, :string unless column_exists?(:bank_statements, :account_mask)
    add_column :bank_statements, :file_digest, :string unless column_exists?(:bank_statements, :file_digest)
    add_column :bank_statements, :source_format, :string unless column_exists?(:bank_statements, :source_format)
    add_column :bank_statements, :error_message, :text unless column_exists?(:bank_statements, :error_message)

    add_index :bank_statements, :file_digest, unique: true unless index_exists?(:bank_statements, :file_digest, unique: true)
    add_index :bank_statements,
              %i[user_id bank_name account_mask period_start period_end],
              unique: true,
              name: "index_bank_statements_unique_period" unless index_exists?(:bank_statements, name: "index_bank_statements_unique_period")

    add_column :categories, :user_id, :bigint unless column_exists?(:categories, :user_id)
    add_column :categories, :kind, :string, null: false, default: "expense" unless column_exists?(:categories, :kind)
    add_column :categories, :is_system, :boolean, null: false, default: false unless column_exists?(:categories, :is_system)
    add_index :categories, :user_id unless index_exists?(:categories, :user_id)
    add_index :categories, :kind unless index_exists?(:categories, :kind)
    add_foreign_key :categories, :users unless foreign_key_exists?(:categories, :users)
  end
end
