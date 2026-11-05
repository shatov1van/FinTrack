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

## Деплой за Cloudflare

Приложение рассчитано на схему `Cloudflare -> HTTPS origin -> Docker/Kamal`.
В Cloudflare выберите режим SSL/TLS **Full (strict)**, укажите origin-сертификат
Cloudflare на сервере и не публикуйте порт PostgreSQL или Docker Registry в интернет.
Production требует переменные `APP_HOST`, `FINTRACK_SERVER`, `KAMAL_REGISTRY_SERVER`,
`KAMAL_REGISTRY_USERNAME`, `KAMAL_REGISTRY_PASSWORD`, `FINTRACK_DATABASE_PASSWORD` и
`RAILS_MASTER_KEY`. Реальные значения передаются через менеджер секретов, а не через Git.

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
