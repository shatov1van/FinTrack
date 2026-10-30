require "csv"
require "digest"
require "date"
require "bigdecimal"
require "pdf-reader"
require "roo"

class StatementImporter
  class Error < StandardError; end

  MAX_FILE_SIZE = 10.megabytes
  EXTENSIONS = %w[csv xlsx xls pdf].freeze

  def self.call(user:, uploaded_file:)
    new(user:, uploaded_file:).call
  end

  def initialize(user:, uploaded_file:)
    @user = user
    @uploaded_file = uploaded_file
  end

  def call
    validate_file!
    bytes = File.binread(uploaded_file.tempfile.path)
    digest = Digest::SHA256.hexdigest(bytes)
    raise Error, "Этот файл уже импортирован." if user.bank_statements.exists?(file_digest: digest)

    rows = parse_rows
    raise Error, "В файле не найдены транзакции." if rows.empty?

    statement = user.bank_statements.create!(
      bank_name: "Не указан",
      file_name: uploaded_file.original_filename,
      file_digest: digest,
      source_format: extension,
      status: "processing"
    )

    ActiveRecord::Base.transaction do
      rows.each { |row| create_transaction!(statement, row) }
      statement.update!(
        status: "completed",
        period_start: statement.financial_transactions.minimum(:transaction_date),
        period_end: statement.financial_transactions.maximum(:transaction_date)
      )
    end
    statement
  rescue ActiveRecord::RecordInvalid => e
    statement&.update(status: "failed", error_message: e.message)
    raise Error, e.record.errors.full_messages.to_sentence
  rescue Error
    raise
  rescue StandardError => e
    statement&.update(status: "failed", error_message: e.message)
    raise Error, "Не удалось обработать файл: #{e.message}"
  end

  private

  attr_reader :user, :uploaded_file

  def validate_file!
    raise Error, "Выберите файл." if uploaded_file.blank?
    raise Error, "Размер файла не должен превышать 10 МБ." if uploaded_file.size > MAX_FILE_SIZE
    raise Error, "Поддерживаются только CSV, Excel и PDF." unless EXTENSIONS.include?(extension)
  end

  def extension
    File.extname(uploaded_file.original_filename.to_s).delete(".").downcase
  end

  def parse_rows
    case extension
    when "csv" then parse_csv
    when "xlsx", "xls" then parse_spreadsheet
    when "pdf" then parse_pdf
    end
  end

  def parse_csv
    content = File.read(uploaded_file.tempfile.path, encoding: "bom|utf-8")
    delimiter = content.lines.first.to_s.count(";") > content.lines.first.to_s.count(",") ? ";" : ","
    CSV.parse(content, headers: true, col_sep: delimiter).filter_map { |row| normalize_row(row.to_h) }
  rescue CSV::MalformedCSVError, ArgumentError => e
    raise Error, "CSV имеет неверный формат: #{e.message}"
  end

  def parse_spreadsheet
    spreadsheet = Roo::Spreadsheet.open(uploaded_file.tempfile.path, extension: extension.to_sym)
    headers = spreadsheet.row(1).map { |header| header.to_s }
    (2..spreadsheet.last_row).filter_map do |number|
      normalize_row(headers.zip(spreadsheet.row(number)).to_h)
    end
  rescue Roo::Error => e
    raise Error, "Excel имеет неверный формат: #{e.message}"
  end

  def parse_pdf
    text = PDF::Reader.new(uploaded_file.tempfile.path).pages.map(&:text).join("\n")
    text.lines.filter_map do |line|
      date_match = line.match(/\b(\d{1,2}[.\/-]\d{1,2}[.\/-]\d{2,4}|\d{4}-\d{2}-\d{2})\b/)
      amount_match = line.match(/[-+]?\d[\d\s]*(?:[.,]\d{1,2})?\s*(?:₽|RUB|руб\.)?/i)
      next unless date_match && amount_match

      amount = parse_amount(amount_match[0])
      {
        date: parse_date(date_match[1]),
        merchant: line.delete_prefix(date_match[0]).delete(amount_match[0]).strip,
        amount: amount.abs,
        transaction_type: amount.negative? ? "expense" : "income"
      }
    end
  rescue PDF::Reader::MalformedPDFError, ArgumentError => e
    raise Error, "PDF имеет неверный формат: #{e.message}"
  end

  def normalize_row(raw)
    values = raw.transform_keys { |key| normalize_header(key) }
    merchant = value_for(values, "merchant", "description", "operation", "назначение", "описание")
    date = value_for(values, "date", "transaction_date", "дата")
    amount_key = values.key?("debit") ? "debit" : values.key?("credit") ? "credit" : nil
    amount_key ||= values.keys.find { |key| key.include?("amount") || key.include?("sum") || key.include?("сумм") }
    amount_value = values[amount_key] if amount_key
    return if merchant.blank? || date.blank? || amount_value.blank?

    amount = parse_amount(amount_value)
    type = value_for(values, "transaction_type", "type", "тип")
    type = type.to_s.downcase
    if !%w[income expense].include?(type)
      type = if type.include?("income") || type.include?("доход") || type.include?("приход")
        "income"
      elsif type.include?("expense") || type.include?("расход") || type.include?("спис")
        "expense"
      else
        amount_key == "credit" || amount.positive? ? "income" : "expense"
      end
    end
    { date: parse_date(date), merchant: merchant.to_s.strip, amount: amount.abs, transaction_type: type }
  rescue ArgumentError
    nil
  end

  def value_for(values, *keys)
    keys.each do |key|
      return values[key] if values[key].present?
    end
    values.find { |header, value| value.present? && keys.any? { |key| header.include?(key) } }&.last
  end

  def normalize_header(header)
    header.to_s.strip.downcase.gsub(/[[:space:]]+/, "_")
  end

  def parse_amount(value)
    normalized = value.to_s.tr("\u00a0", " ").gsub(/[^\d,.\-+]/, "").delete(" ")
    if normalized.include?(",") && normalized.include?(".")
      normalized = normalized.rindex(",") > normalized.rindex(".") ? normalized.delete(".").tr(",", ".") : normalized.delete(",")
    elsif normalized.include?(",")
      normalized = normalized.match?(/,\d{1,2}\z/) ? normalized.tr(",", ".") : normalized.delete(",")
    elsif normalized.match?(/\.\d{3}\z/)
      normalized = normalized.delete(".")
    end
    BigDecimal(normalized)
  end

  def parse_date(value)
    Date.strptime(value.to_s.strip, "%d.%m.%Y")
  rescue Date::Error
    Date.parse(value.to_s)
  end

  def create_transaction!(statement, row)
    statement.financial_transactions.create!(
      amount: row[:amount],
      transaction_type: row[:transaction_type],
      transaction_date: row[:date],
      merchant: row[:merchant]
    ).auto_categorize!
  end
end
