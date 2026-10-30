# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
[
  [ "Продукты", "#3b82f6", "пятерочка, магнит, перекресток, ашан, лента" ],
  [ "Кафе и рестораны", "#f97316", "dodo, вкусно и точка, ресторан, кафе" ],
  [ "Транспорт", "#8b5cf6", "такси, uber, yandex go, метро, автобус" ],
  [ "Подписки", "#a855f7", "yandex.plus, netflix, spotify, okko, youtube" ],
  [ "Зарплата", "#22c55e", "зарплата, зачисление" ],
  [ "Переводы", "#64748b", "перевод, transfer" ]
].each do |name, color, keywords|
  Category.find_or_create_by!(name:, user_id: nil) do |category|
    category.color = color
    category.keywords = keywords
    category.kind = name == "Зарплата" ? "income" : "expense"
    category.is_system = true
  end
end
