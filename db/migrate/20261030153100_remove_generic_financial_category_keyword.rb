class RemoveGenericFinancialCategoryKeyword < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE categories
      SET keywords = 'комиссия, обслуживание карты, брокер, инвестици, кредит, рассрочк, страхов'
      WHERE name = 'Финансовые услуги' AND user_id IS NULL AND is_system = TRUE
    SQL
  end

  def down
    execute <<~SQL
      UPDATE categories
      SET keywords = 'банк, комиссия, обслуживание карты, брокер, инвестици, кредит, рассрочк, страхов'
      WHERE name = 'Финансовые услуги' AND user_id IS NULL AND is_system = TRUE
    SQL
  end
end
