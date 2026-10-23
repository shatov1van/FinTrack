class CreateBankStatements < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_statements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :bank_name
      t.string :file_name
      t.string :status
      t.date :period_start
      t.date :period_end

      t.timestamps
    end
  end
end
