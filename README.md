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
на подписку. Повторная загрузка того же файла для одного пользователя блокируется по SHA-256.
Сканированные PDF без текстового слоя и OCR пока не поддерживаются.

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
