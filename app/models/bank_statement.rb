class BankStatement < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  # АССОЦИАЦИИ
  belongs_to :user
  has_many :financial_transactions, dependent: :destroy

  # ВАЛИДАЦИИ
  validates :bank_name, presence: true
  validates :file_name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :period_end_after_period_start

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
