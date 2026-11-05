Проект "Трекер финансов"

Это веб-приложение анализирующее данные о банковских расходах пользователя за какой-то период.

## Локальный запуск

Требуются Ruby 3.4.8, PostgreSQL и Bundler.

```powershell
bundle install
$env:POSTGRES_PASSWORD="ваш_пароль"
bin/rails db:prepare
bin/dev
```

Для PostgreSQL можно задать `POSTGRES_USER`, `POSTGRES_HOST` и `POSTGRES_PORT`; значения по
умолчанию — `postgres`, `localhost` и `5432`. Пароли не хранятся в `config/database.yml` и
не должны добавляться в Git. Файлы `.env*` и ключ Rails уже исключены в [.gitignore](.gitignore).

## MVP-импорт

Авторизованный пользователь загружает CSV, XLSX/XLS или текстовый PDF на `/import`.
Ограничение размера — 10 МБ. Для CSV/Excel распознаются столбцы с датой, мерчантом/описанием,
суммой и необязательным типом операции. Рекомендуемый CSV-заголовок:

```text
date,merchant,amount,transaction_type
2026-10-01,ПЯТЕРОЧКА,-1500,expense
2026-10-02,ЗАРПЛАТА,100000,income
```

Каждая транзакция сохраняется в PostgreSQL, получает категорию по ключевым словам и проверяется
на подписку. После загрузки файл обрабатывается через `ParseStatementJob`, а состояние можно
отслеживать на странице `/bank_statements`: `pending`, `needs_bank_selection`, `parsed` или
`error`. Для PDF используется автоопределение Сбербанка и Т-Банка; для неизвестного формата доступен
ручной выбор банка. Каждый поддержанный банк может иметь отдельный адаптер формата, а для
неизвестных банков используется общий PDF-парсер. Повторная загрузка того же файла для
одного пользователя блокируется по SHA-256, а совпавшие операции между выписками пропускаются.
Выписку можно архивировать без удаления операций из базы; архивные данные не участвуют в dashboard.
Merchant в таблице сокращается только визуально, полный текст сохраняется. Сканированные PDF без
текстового слоя и OCR пока не поддерживаются.

После обновления проекта примените новые миграции:

```powershell
ruby bin/rails db:migrate
```

Страница импорта автоматически обновляет список операций во время фонового парсинга, поэтому
ручное обновление страницы после завершения job не требуется.

## Деплой за Cloudflare и Neon

Это Rails-приложение нельзя деплоить как Cloudflare Pages static site:
`public/` содержит только статические assets и error pages, а маршрут `/` должен
обрабатываться Rails/Puma. Cloudflare Pages с `pages_build_output_dir = "./public"`
будет возвращать 404, потому что `public/index.html` отсутствует.

Рабочая схема: `Cloudflare DNS/proxy -> HTTPS origin (VPS/Docker/Kamal) -> Neon PostgreSQL`.
Neon — это только база данных, он не запускает Rails-приложение.
В Cloudflare выберите режим SSL/TLS **Full (strict)**, укажите origin-сертификат
Cloudflare на сервере и не публикуйте порт PostgreSQL или Docker Registry в интернет.
Production требует переменные `APP_HOST`, `FINTRACK_SERVER`, `KAMAL_REGISTRY_SERVER`,
`KAMAL_REGISTRY_USERNAME`, `KAMAL_REGISTRY_PASSWORD`, `FINTRACK_DATABASE_PASSWORD` и
`RAILS_MASTER_KEY`. Для Neon также задайте `DATABASE_URL` с connection string из Neon
и `sslmode=require`; переменная должна быть доступна контейнеру Rails в production.
Реальные значения передаются через менеджер секретов, а не через Git.

Проверка по шагам:

1. Сначала откройте `https://ORIGIN_HOST/up` напрямую или через Cloudflare. Должен
   вернуться HTTP 200. Если `/up` не отвечает, проблема в VPS/Docker/Kamal, а не в Neon.
2. Проверьте, что DNS-запись домена указывает на публичный IP VPS, а proxy status
   Cloudflare включен только после проверки origin.
3. В Cloudflare установите SSL/TLS **Full (strict)** и убедитесь, что origin принимает
   HTTPS на 443. Не используйте режим **Flexible**.
4. В переменной `APP_HOST` указывайте только hostname, например `app.example.com`,
   без `https://` и без пути. Если используется `www`, добавьте его в
   `APP_HOST_ALIASES` через запятую.
5. В Neon скопируйте pooled или direct connection string с `sslmode=require`.
   Проверьте, что роль имеет права на создание/изменение таблиц, затем выполните
   `bin/rails db:prepare` внутри production-контейнера.
6. Посмотрите логи origin командой `bin/kamal logs`. Если запросы не появляются,
   Cloudflare не доходит до origin; если появляются ошибки подключения, проверяйте
   `DATABASE_URL`, `RAILS_MASTER_KEY` и доступ Neon.

`wrangler.toml` намеренно не хранится в репозитории: Wrangler Pages/Workers не является
runtime для этого Rails-приложения. Если нужен именно Cloudflare Pages, потребуется
отдельный frontend и API, а текущий Rails-монолит туда переносить нельзя.

Файл `.kamal/secrets.example` — только шаблон. Скопируйте его локально в
`.kamal/secrets`; рабочий файл игнорируется Git.

### Что нельзя добавлять в Git

Никогда не публикуйте и не отслеживайте:

- `config/master.key`, любые `*.key`, `config/credentials/*.key`;
- `.env`, `.env.*` и локальные файлы с переменными окружения;
- `.kamal/secrets`;
- загруженные банковские файлы и содержимое `storage/`;
- логи, дампы БД, временные файлы и содержимое `tmp/`;
- production-конфигурации с паролями, токенами, приватными ключами или cookie secrets;
- резервные копии, скриншоты и экспортированные CSV/PDF/XLS/XLSX с персональными данными.

В Git допускаются только зашифрованные Rails credentials
`config/credentials.yml.enc`, шаблоны вроде `.kamal/secrets.example` и пустые
файлы `.keep`. Перед публикацией проверяйте `git status`, `git ls-files` и историю
репозитория; если секрет уже был закоммичен, одной записи в `.gitignore` недостаточно —
секрет нужно немедленно отозвать и удалить из истории.

## Тестирование

```powershell
$env:POSTGRES_PASSWORD="ваш_пароль"
$env:RAILS_ENV="test"
bin/rails db:test:prepare
bundle exec rspec
bin/rails test
bundle exec rubocop
bundle exec brakeman --no-pager
```
