module ApplicationHelper
  POPULAR_BANKS = [
    [ "Сбербанк", "Сбербанк" ],
    [ "Т-Банк", "Т-Банк" ],
    [ "Альфа-Банк", "Альфа-Банк" ],
    [ "ВТБ", "ВТБ" ],
    [ "Газпромбанк", "Газпромбанк" ],
    [ "Райффайзенбанк", "Райффайзенбанк" ],
    [ "Россельхозбанк", "Россельхозбанк" ],
    [ "Открытие", "Открытие" ],
    [ "Совкомбанк", "Совкомбанк" ],
    [ "МКБ", "МКБ" ],
    [ "Росбанк", "Росбанк" ],
    [ "Почта Банк", "Почта Банк" ],
    [ "ЮMoney", "ЮMoney" ],
    [ "Другой банк", "Другой" ]
  ].freeze

  def popular_banks
    POPULAR_BANKS
  end

  def merchant_label(merchant, limit: 34)
    normalized = merchant.to_s.gsub(/\s+/, " ").strip
    truncate(normalized, length: limit, omission: "…")
  end
end
