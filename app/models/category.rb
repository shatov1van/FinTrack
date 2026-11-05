class Category < ApplicationRecord
  belongs_to :user, optional: true
  # АССОЦИАЦИИ: При удалении категории транзакции не удаляются, у них просто обнуляется category_id (nullify)
  has_many :financial_transactions, dependent: :nullify

  # ВАЛИДАЦИИ
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :color, presence: true
  validates :kind, inclusion: { in: %w[income expense] }

  # БИЗНЕС-ЛОГИКА: Метод для AI-категоризатора.
  # Ищет категорию, чьи ключевые слова (keywords через запятую) совпадают с названием мерчанта из выписки.
  def self.detect_for_merchant(merchant_name, user: nil)
    return nil if merchant_name.blank?

    normalized_merchant = merchant_name.downcase
    where(user_id: [ nil, user&.id ]).filter_map do |category|
      next if category.keywords.blank?

      keywords_list = category.keywords.downcase.split(",").map(&:strip)
      matched_keyword = keywords_list.select { |keyword| keyword_match?(normalized_merchant, keyword) }.max_by(&:length)
      [ category, matched_keyword.length ] if matched_keyword
    end.max_by { |_category, keyword_length| keyword_length }&.first
  end

  def self.keyword_match?(merchant, keyword)
    return false if keyword.blank?

    normalized_keyword = keyword.downcase.strip
    return merchant.include?(normalized_keyword) if normalized_keyword.length > 3 || normalized_keyword.include?(" ")

    merchant.match?(/(?:\A|[^[:alnum:]])#{Regexp.escape(normalized_keyword)}(?:\z|[^[:alnum:]])/)
  end
  private_class_method :keyword_match?
end
