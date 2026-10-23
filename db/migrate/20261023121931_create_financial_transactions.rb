class CreateFinancialTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :financial_transactions do |t|
      t.references :bank_statement, null: false, foreign_key: true
      # null: true позволяет сохранить транзакцию до того, как AI определит категорию
      t.references :category, null: true, foreign_key: true
      # precision: 10, scale: 2 означает до 10 цифр всего и ровно 2 знака после запятой (копейки)
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :transaction_type, null: false
      t.date :transaction_date, null: false
      t.string :merchant, null: false
      t.boolean :is_subscription, default: false

      t.timestamps
    end
  end
end
