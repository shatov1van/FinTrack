class AddStatementProcessingFields < ActiveRecord::Migration[8.1]
  def change
    add_column :bank_statements, :archived, :boolean, null: false, default: false unless column_exists?(:bank_statements, :archived)
    add_column :bank_statements, :imported_count, :integer, null: false, default: 0 unless column_exists?(:bank_statements, :imported_count)
    add_column :bank_statements, :duplicate_count, :integer, null: false, default: 0 unless column_exists?(:bank_statements, :duplicate_count)

    add_index :financial_transactions,
              %i[bank_statement_id transaction_date amount merchant],
              unique: true,
              name: "index_financial_transactions_on_statement_and_identity" unless index_exists?(:financial_transactions, name: "index_financial_transactions_on_statement_and_identity")

    reversible do |direction|
      direction.up do
        execute <<~SQL
          UPDATE bank_statements
          SET status = CASE status
            WHEN 'completed' THEN 'parsed'
            WHEN 'failed' THEN 'error'
            ELSE status
          END
        SQL
      end
    end
  end
end
