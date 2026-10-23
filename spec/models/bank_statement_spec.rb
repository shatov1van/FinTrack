require 'rails_helper'

RSpec.describe BankStatement, type: :model do
  let(:user) { User.create!(email: 'test@fintrack.ru', password: 'password123') }

  describe 'Валидации' do
    context 'когда все обязательные поля заполнены корректно' do
      it 'выписка считается валидной' do
        statement = BankStatement.new(
          user: user,
          bank_name: 'Сбербанк',
          file_name: 'sber_oct.pdf',
          status: 'completed',
          period_start: Date.new(2026, 10, 1),
          period_end: Date.new(2026, 10, 31)
        )
        expect(statement).to be_valid
      end
    end

    context 'когда переданы некорректные данные' do
      it 'выдает ошибку при неизвестном статусе обработки' do
        statement = BankStatement.new(user: user, bank_name: 'Т-Банк', file_name: 'tbank.csv', status: 'unknown_status')
        expect(statement).not_to be_valid
      end

      it 'выдает ошибку, если дата окончания периода раньше даты начала' do
        statement = BankStatement.new(
          user: user,
          bank_name: 'Альфа-Банк',
          file_name: 'alfa.xlsx',
          status: 'pending',
          period_start: Date.new(2026, 10, 20),
          period_end: Date.new(2026, 10, 10)
        )
        expect(statement).not_to be_valid
        expect(statement.errors[:period_end]).to include("не может быть раньше даты начала периода")
      end
    end
  end

  describe 'Бизнес-логика: подсчет финансов (#total_income, #total_expenses, #net_balance)' do
    let(:statement) do
      BankStatement.create!(user: user, bank_name: 'Сбербанк', file_name: 'statement.csv', status: 'completed')
    end

    context 'когда в выписке есть и доходы, и расходы' do
      before do
        statement.financial_transactions.create!(amount: 100_000, transaction_type: 'income', transaction_date: Date.today, merchant: 'ЗАРПЛАТА')
        statement.financial_transactions.create!(amount: 15_000, transaction_type: 'expense', transaction_date: Date.today, merchant: 'ПЯТЕРОЧКА')
        statement.financial_transactions.create!(amount: 5_000, transaction_type: 'expense', transaction_date: Date.today, merchant: 'АПТЕКА')
      end

      it 'правильно считает сумму доходов' do
        expect(statement.total_income).to eq(100_000)
      end

      it 'правильно считает сумму расходов' do
        expect(statement.total_expenses).to eq(20_000)
      end

      it 'правильно рассчитывает чистый баланс (сальдо)' do
        expect(statement.net_balance).to eq(80_000)
      end
    end

    context 'когда выписка пустая (без транзакций)' do
      it 'возвращает нули для всех показателей' do
        expect(statement.total_income).to eq(0)
        expect(statement.total_expenses).to eq(0)
        expect(statement.net_balance).to eq(0)
      end
    end
  end
end
