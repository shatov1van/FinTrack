class ExpandSystemCategoryKeywords < ActiveRecord::Migration[8.1]
  CATEGORY_KEYWORDS = {
    "Продукты" => "продукт, супермаркет, супермаркеты, магазин, пятерочка, перекресток, магнит, дикси, ашан, лента, окей, вкусвилл",
    "Кафе и рестораны" => "dodo, додо, вкусно и точка, макдональдс, ресторан, кафе, кофейня, столовая, пицца, burger, sushi",
    "Транспорт" => "такси, uber, yandex go, яндекс такси, метро, автобус, трамвай, троллейбус, электричка, ржд, транспорт",
    "Подписки" => "yandex.plus, яндекс плюс, netflix, spotify, okko, ivi, kinopoisk, youtube, telegram premium, apple.com/bill, google play",
    "Переводы" => "перевод, перевод сбп, сбп, transfer, пополнение карты, пополнен",
    "Коммунальные услуги" => "жкх, коммуналь, электрич, электроэнерг, газ, вода, отоплен, капремонт, управляющая компания, квартплата",
    "Связь и интернет" => "мегафон, мтс, билайн, tele2, t2, ростелеком, йота, yota, мобильн, интернет, связь",
    "Здоровье" => "аптека, аптеки, клиника, врач, стоматолог, лаборатор, здоровье, медцентр, анализ",
    "Одежда и обувь" => "одежда, обувь, zara, hm, lamoda, wildberries, вайлдберриз, ozon",
    "Дом и ремонт" => "дом, ремонт, мебель, стройматериал, икеа, hoff, leroy merlin, леруа, сантехник",
    "Развлечения" => "кино, театр, игра, steam, playstation, xbox, концерт, клуб, боулинг, музей, парк",
    "Автомобиль" => "азс, бензин, заправка, автомойка, ремонт авто, автосервис, шиномонтаж, штраф, каршеринг",
    "Образование" => "обучение, курс, школа, университет, учеб, репетитор, skillbox, geekbrains",
    "Налоги и государство" => "налог, госпошлина, госуслуги, фнс, пфр, гибдд, пошлина",
    "Снятие наличных" => "снятие наличных, банкомат, atm, cash withdrawal",
    "Финансовые услуги" => "комиссия, обслуживание карты, брокер, инвестици, кредит, рассрочк, страхов",
    "Путешествия" => "авиабилет, самолет, аэропорт, отель, гостиница, booking, travel, поездка, тур",
    "Красота и уход" => "салон, парикмахер, косметолог, маникюр, педикюр, барбершоп, косметика",
    "Благотворительность" => "благотвор, пожертвован, фонд"
  }.freeze

  def up
    CATEGORY_KEYWORDS.each do |name, keywords|
      execute <<~SQL
        UPDATE categories
        SET keywords = #{connection.quote(keywords)}
        WHERE name = #{connection.quote(name)} AND user_id IS NULL AND is_system = TRUE
      SQL
    end

    [
      [ "Финансовые услуги", "#0f766e", "expense" ],
      [ "Путешествия", "#0284c7", "expense" ],
      [ "Красота и уход", "#db2777", "expense" ],
      [ "Благотворительность", "#16a34a", "expense" ]
    ].each do |name, color, kind|
      execute <<~SQL
        INSERT INTO categories (name, color, keywords, kind, is_system, user_id, created_at, updated_at)
        SELECT #{connection.quote(name)}, #{connection.quote(color)}, #{connection.quote(CATEGORY_KEYWORDS.fetch(name))},
               #{connection.quote(kind)}, TRUE, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        WHERE NOT EXISTS (
          SELECT 1 FROM categories WHERE name = #{connection.quote(name)} AND user_id IS NULL
        )
      SQL
    end
  end

  def down
    # Keyword expansion is intentionally not destructive on rollback.
  end
end
