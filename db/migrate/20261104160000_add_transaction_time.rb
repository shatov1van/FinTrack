class AddTransactionTime < ActiveRecord::Migration[8.1]
  def change
    add_column :financial_transactions, :transaction_time, :time unless column_exists?(:financial_transactions, :transaction_time)

    remove_index :financial_transactions, name: "index_financial_transactions_on_statement_and_identity",
                 if_exists: true
    add_index :financial_transactions,
              %i[bank_statement_id transaction_date transaction_time amount merchant],
              unique: true,
              name: "index_financial_transactions_on_statement_and_identity"
  end
end
