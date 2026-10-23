require 'rails_helper'

RSpec.describe FinancialTransaction, type: :model do
  let(:user) { User.create!(email: 'user@fintrack.ru', password: 'password123') }
  let(:statement) { BankStatement.create!(user: user, bank_name: 'Т-Банк', file_name: 'export.csv', status: 'completed') }

  describe 'Бизнес-логика: #auto_categorize! (AI-категоризатор и поиск подписок)' do
    let!(:food_category) { Category.create!(name: 'Продукты', color: 'blue', keywords: 'пятерочка, магнит, перекресток') }
    let!(:sub_category) { Category.create!(name: 'Подписки', color: 'purple', keywords: 'yandex.plus, netflix, spotify') }

    context 'когда мерчант совпадает с ключевыми словами категории продуктов' do
      it 'автоматически присваивает категорию "Продукты" и не помечает как подписку' do
        tx = statement.financial_transactions.create!(
          amount: 1500, transaction_type: 'expense', transaction_date: Date.today, merchant: 'OOO ПЯТЕРОЧКА 124'
        )
        tx.auto_categorize!

        expect(tx.category).to eq(food_category)
        expect(tx.is_subscription).to be(false)
      end
    end

    context 'когда транзакция является регулярным сервисом подписки' do
      it 'присваивает категорию "Подписки" и ставит флаг is_subscription = true' do
        tx = statement.financial_transactions.create!(
          amount: 299, transaction_type: 'expense', transaction_date: Date.today, merchant: 'YANDEX.PLUS MOSCOW'
        )
        tx.auto_categorize!

        expect(tx.category).to eq(sub_category)
        expect(tx.is_subscription).to be(true)
      end
    end

    context 'когда мерчант неизвестен системе' do
      it 'оставляет категорию пустой (nil) и флаг подписки false' do
        tx = statement.financial_transactions.create!(
          amount: 500, transaction_type: 'expense', transaction_date: Date.today, merchant: 'IP NEIZVESTNYI M.M.'
        )
        tx.auto_categorize!

        expect(tx.category).to be_nil
        expect(tx.is_subscription).to be(false)
      end
    end
  end

  describe 'Бизнес-логика: #large_expense? (Определение крупных трат)' do
    context 'когда расход превышает или равен порогу (по умолчанию 10 000 ₽)' do
      it 'возвращает true' do
        tx = FinancialTransaction.new(amount: 15_000, transaction_type: 'expense')
        expect(tx.large_expense?).to be(true)
      end
    end

    context 'когда расход меньше порога' do
      it 'возвращает false' do
        tx = FinancialTransaction.new(amount: 500, transaction_type: 'expense')
        expect(tx.large_expense?).to be(false)
      end
    end

    context 'когда операция на большую сумму является доходом (зарплата)' do
      it 'возвращает false, так как это не расход' do
        tx = FinancialTransaction.new(amount: 150_000, transaction_type: 'income')
        expect(tx.large_expense?).to be(false)
      end
    end
  end
end
