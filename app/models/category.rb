class Category < ApplicationRecord
  SYSTEM_CATEGORIES = [
    [ "Продукты", "#3b82f6", %w[
      продукт продукты супермаркет супермаркеты supermarket supermarkets grocery groceries
      пятерочка pyaterochka пятёрочка магнит magnit перекресток perekrestok
      перекрёсток дикси dixy dixi лента lenta ашан auchan окей okay вкусвилл vkusvill
      чижик chizhik метро cash carry metro cash carry spar спар victoria виктория
      глобус globus карусель радуга billa билла самокат samokat лавка lavka
      азбука вкуса азбука-вкуса вкусно
      walmart target costco tesco aldi lidl carrefour kroger wholefoods traderjoes
    ].join(", "), "expense" ],
    [ "Кафе и рестораны", "#f97316", %w[
      ресторан рестораны кафе кофейня кофейни пицца pizza sushi суши
      вкусно-и-точка вкусно точка вкусноиточка mcdonalds mcdonald's макдональдс
      макдоналдс kfc ростикс rostics burgerking burger-king burgerking
      бургеркинг бургер кинг burger subway starbucks старбакс dodo додо додо-пицца
      papa-johns папа-джонс domino's dominos domino-pizza теремок чайхона
      шоколадница surf-coffee surfcoffee costa-coffee dunkin dunkin-donuts
      taco-bell wendys five-guys shake-shack
    ].join(", "), "expense" ],
    [ "Маркетплейсы", "#8b5cf6", %w[
      ozon озон wildberries вайлдберриз wb валберис валбериз яндекс-маркет
      yandex-market маркет aliexpress алиэкспресс ali-express amazon amazon.com ebay
      temu shein shopee lazada jd.com lamoda ламода мегамаркет megamarket
      сбермегамаркет
    ].join(", "), "expense" ],
    [ "Покупки", "#64748b", %w[
      магазин magazin магазины store stores shop shops retail покупки
    ].join(", "), "expense" ],
    [ "Одежда и обувь", "#ec4899", %w[
      одежда обувь zara зара hm h&m uniqlo mango манго bershka pull&bear
      stradivarius reserved reebok adidas nike puma new-balance converse
      decathlon декатлон спортмастер
    ].join(", "), "expense" ],
    [ "Электроника", "#0f766e", %w[
      электроника техника dns днс мвидео м-видео eldorado эльдорадо citilink
      ситилинк re-store restore apple-store samsung
      mediamarkt bestbuy best-buy xiaomi сяоми
    ].join(", "), "expense" ],
    [ "Транспорт", "#8b5cf6", %w[
      такси taxi uber yandex-go яндекс-го яндекс-такси яндекс go lyft bolt
      метро автобус автобусы трамвай троллейбус электричка общественный
      транспорт ржд russian-railways railway поезд train citymobil ситимобил
      maxim таксовичкоф
    ].join(", "), "expense" ],
    [ "Автомобиль", "#475569", %w[
      азс бензин заправка заправки автомойка автосервис шиномонтаж роснефть
      rosneft лукойл lukoil газпромнефть gazpromneft татнефть
      tatneft shell bp exxonmobil mobil chevron circle-k carwash автозапчасти
      каршеринг делимобиль ситидрайв belka-car штраф гибдд
    ].join(", "), "expense" ],
    [ "Подписки", "#a855f7", %w[
      yandex.plus яндекс.плюс яндекс плюс netflix spotify
      okko окко ivi иви kinopoisk кинопоиск youtube-premium telegram-premium
      apple.com/bill google-play google play google*
      patreon boosty twitch amazon-prime disney+ hulu hbo max apple-music
      apple-tv icloud adobe microsoft xbox-game-pass playstation-plus
    ].join(", "), "expense" ],
    [ "Зарплата", "#22c55e", %w[
      зарплата зачисление зарплаты аванс премия доход вознаграждение salary payroll
      wages paycheck
    ].join(", "), "income" ],
    [ "Переводы", "#64748b", %w[
      перевод переводы перевод-сбп сбп быстрых-платежей система-быстрых-платежей
      пополнение пополнить пополнения перевод-на-карту transfer transfers
      payment-to-card card-transfer money-transfer p2p peer-to-peer
    ].join(", "), "expense" ],
    [ "Коммунальные услуги", "#0ea5e9", %w[
      жкх коммунальные коммуналь электричество электроэнергия газ вода отопление
      капремонт управляющая-компания квартплата коммунальные-услуги utilities
      utility electric electricity water gas rent
    ].join(", "), "expense" ],
    [ "Связь и интернет", "#06b6d4", %w[
      мегафон megafon мтс mts билайн beeline tele2 t2 ростелеком rostelecom
      йота yota мобильный интернет связь телефон telecom broadband
      verizon at&t t-mobile vodafone orange
    ].join(", "), "expense" ],
    [ "Здоровье", "#ef4444", %w[
      аптека аптеки аптечный pharmacy pharmacies здоровье клиника врач стоматолог
      лаборатория медцентр анализ медицинский 36.6 горздрав ригла еаптека
      apteka.ru invitro гемотест medclinic cvs walgreens boots
    ].join(", "), "expense" ],
    [ "Дом и ремонт", "#f59e0b", %w[
      ремонт мебель стройматериалы икеа ikea hoff леруа лемана-про leroy-merlin
      castorama home-depot lowes obi оби сантехника хозяйственный хозяйственные
      товары мебельный для дома
    ].join(", "), "expense" ],
    [ "Развлечения", "#8b5cf6", %w[
      кинотеатр кино театр игра steam playstation xbox концерт клуб боулинг музей
      парк развлечения ticketmaster кино-поиск кинотеатры amc cineworld
      eventbrite цирк зоопарк
    ].join(", "), "expense" ],
    [ "Образование", "#14b8a6", %w[
      обучение курс школа университет учеба репетитор skillbox geekbrains
      coursera udemy stepik netology skillshare duolingo образовательный
      образование
    ].join(", "), "expense" ],
    [ "Налоги и государство", "#78716c", %w[
      налог налоги госпошлина госуслуги фнс пфр гибдд пошлина налоговая
      government tax taxes irs
    ].join(", "), "expense" ],
    [ "Снятие наличных", "#334155", %w[
      снятие-наличных снятие наличных банкомат atm cash-withdrawal cash withdrawal
    ].join(", "), "expense" ],
    [ "Финансовые услуги", "#0f766e", %w[
      комиссия обслуживание-карты брокер инвестиции кредит рассрочка страховка
      банк банковская-услуга банковские-услуги loan interest brokerage
      financial-service
    ].join(", "), "expense" ],
    [ "Путешествия", "#0284c7", %w[
      авиабилет самолет аэропорт отель гостиница booking travel поездка тур
      авиакомпания авиабилеты airbnb expedia hotels.com trip.com авиасейлс
      aviasales american-airlines delta united emirates
    ].join(", "), "expense" ],
    [ "Красота и уход", "#db2777", %w[
      салон парикмахер косметолог маникюр педикюр барбершоп косметика beauty
      sephora золотое-яблоко летуаль рив-гош ile-de-beaute
    ].join(", "), "expense" ],
    [ "Спорт и фитнес", "#16a34a", %w[
      спорт фитнес спортзал тренажерный-клуб абонемент бассейн йога gym fitness
      crossfit worldclass world-class xfit
    ].join(", "), "expense" ],
    [ "Питомцы", "#a16207", %w[
      ветеринар ветеринарная клиника зоомагазин корм для-животных питомец pet
      pets petco petsmart
    ].join(", "), "expense" ],
    [ "Страхование", "#0e7490", %w[
      страхование страховка страховая insurance insurer осаго каско
    ].join(", "), "expense" ],
    [ "Благотворительность", "#16a34a", %w[
      благотворительность пожертвование фонд charity donation donate
    ].join(", "), "expense" ],
    [ "Неопределено", "#94a3b8", "", "expense" ]
  ].freeze

  belongs_to :user, optional: true
  # АССОЦИАЦИИ: При удалении категории транзакции не удаляются, у них просто обнуляется category_id (nullify)
  has_many :financial_transactions, dependent: :nullify

  # ВАЛИДАЦИИ
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :color, presence: true
  validates :kind, inclusion: { in: %w[income expense] }

  def self.sync_system_categories!
    SYSTEM_CATEGORIES.each do |name, color, keywords, kind|
      category = find_or_initialize_by(name:, user_id: nil)
      category.assign_attributes(color:, keywords:, kind:, is_system: true)
      category.save! if category.new_record? || category.changed?
    end
  end

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
