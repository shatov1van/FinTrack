class Category < ApplicationRecord
  # АССОЦИАЦИИ: При удалении категории транзакции не удаляются, у них просто обнуляется category_id (nullify)
  has_many :financial_transactions, dependent: :nullify

  # ВАЛИДАЦИИ
  validates :name, presence: true, uniqueness: true
  validates :color, presence: true

  # БИЗНЕС-ЛОГИКА: Метод для AI-категоризатора.
  # Ищет категорию, чьи ключевые слова (keywords через запятую) совпадают с названием мерчанта из выписки.
  def self.detect_for_merchant(merchant_name)
    return nil if merchant_name.blank?

    normalized_merchant = merchant_name.downcase
    all.find do |category|
      next if category.keywords.blank?

      keywords_list = category.keywords.downcase.split(",").map(&:strip)
      keywords_list.any? { |keyword| normalized_merchant.include?(keyword) }
    end
  end
end
