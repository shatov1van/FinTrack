class BankStatement < ApplicationRecord
  STATUSES = %w[pending processing completed parsed needs_bank_selection error failed].freeze

  # АССОЦИАЦИИ
  belongs_to :user
  has_many :financial_transactions, dependent: :destroy
  has_one_attached :source_file

  # ВАЛИДАЦИИ
  validates :bank_name, presence: true, unless: :bank_selection_pending?
  validates :file_name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :source_format, inclusion: { in: %w[csv xlsx xls pdf] }, allow_nil: true
  validates :file_digest, uniqueness: { scope: :user_id }, allow_nil: true
  validate :period_end_after_period_start

  scope :active, -> { where(archived: false) }

  def bank_selection_pending?
    bank_name.blank? && %w[pending processing needs_bank_selection].include?(status)
  end

  # БИЗНЕС-ЛОГИКА 1: Сумма всех расходов по конкретной выписке
  def total_expenses
    financial_transactions.where(transaction_type: "expense").sum(:amount)
  end

  # БИЗНЕС-ЛОГИКА 2: Сумма всех доходов по конкретной выписке
  def total_income
    financial_transactions.where(transaction_type: "income").sum(:amount)
  end

  # БИЗНЕС-ЛОГИКА 3: Чистый итог за период выписки (Сальдо)
  def net_balance
    total_income - total_expenses
  end

  private

  # Кастомная валидация дат
  def period_end_after_period_start
    return if period_start.blank? || period_end.blank?

    if period_end < period_start
      errors.add(:period_end, "не может быть раньше даты начала периода")
    end
  end
end
