class FinancialTransaction < ApplicationRecord
  TYPES = %w[income expense].freeze
  SUBSCRIPTION_KEYWORDS = %w[yandex.plus netflix spotifyivi okko telegram youtube patreon boosty].freeze

  # АССОЦИАЦИИ
  belongs_to :bank_statement
  belongs_to :category, optional: true

  # ВАЛИДАЦИИ
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: TYPES }
  validates :transaction_date, presence: true
  validates :merchant, presence: true

  # БИЗНЕС-ЛОГИКА 1: Автоматическое определение категории и проверка на скрытую подписку (AI-Категоризатор)
  def auto_categorize!
    detected_category = Category.detect_for_merchant(merchant, user: bank_statement.user)
    self.category = detected_category || undefined_category

    # Проверяем, входит ли мерчант в список регулярных цифровых подписок
    normalized_merchant = merchant.to_s.downcase
    if SUBSCRIPTION_KEYWORDS.any? { |sub| normalized_merchant.include?(sub) }
      self.is_subscription = true
    end

    save!
  end

  def undefined_category
    Category.find_or_create_by!(name: "Неопределено", user_id: nil) do |category|
      category.color = "#94a3b8"
      category.kind = "expense"
      category.is_system = true
    end
  end

  # БИЗНЕС-ЛОГИКА 2: Проверка, является ли трата крупной (например, от 10 000 руб. для советов по бюджету)
  def large_expense?(threshold = 10_000)
    transaction_type == "expense" && amount >= threshold
  end
end
