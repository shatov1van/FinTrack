class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # АССОЦИАЦИИ: При удалении пользователя удаляются все его выписки (dependent: :destroy)
  has_many :bank_statements, dependent: :destroy
  # Пользователь имеет доступ ко всем своим транзакциям напрямую через выписки
  has_many :financial_transactions, through: :bank_statements

  # БИЗНЕС-ЛОГИКА: Подсчет чистого баланса пользователя по всем банкам (Мультибанкинг)
  def total_balance
    incomes = financial_transactions.where(transaction_type: "income").sum(:amount)
    expenses = financial_transactions.where(transaction_type: "expense").sum(:amount)
    incomes - expenses
  end
end
