require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'Бизнес-логика: .detect_for_merchant' do
    let!(:cafe_category) { Category.create!(name: 'Фастфуд и Кафе', color: 'orange', keywords: 'вкусно и точка, dodo, старбакс') }

    context 'когда название мерчанта содержит ключевое слово (независимо от регистра)' do
      it 'находит и возвращает правильную категорию' do
        result = Category.detect_for_merchant('Оплата DODO PIZZA MSK')
        expect(result).to eq(cafe_category)
      end
    end

    context 'когда мерчант не подходит ни под одно ключевое слово' do
      it 'возвращает nil' do
        result = Category.detect_for_merchant('АЗС ЛУКОЙЛ')
        expect(result).to be_nil
      end
    end

    context 'когда передано пустое значение (nil или пустая строка)' do
      it 'безопасно возвращает nil без сбоя программы' do
        expect(Category.detect_for_merchant(nil)).to be_nil
        expect(Category.detect_for_merchant('')).to be_nil
      end
    end
  end
end
