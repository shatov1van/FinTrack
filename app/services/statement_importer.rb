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

  def initialize(user:, uploaded_file:, statement: nil)
    @user = user
    @uploaded_file = uploaded_file
    @statement = statement
  end

  def call
    validate_file!
    bytes = File.binread(uploaded_file.tempfile.path)
    digest = Digest::SHA256.hexdigest(bytes)
    raise Error, "Этот файл уже импортирован." if user.bank_statements.exists?(file_digest: digest)

    statement = user.bank_statements.create!(
      bank_name: nil,
      file_name: uploaded_file.original_filename,
      file_digest: digest,
      source_format: extension,
      status: "pending"
    )
    self.class.new(user:, uploaded_file:, statement:).process
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.record.errors.full_messages.to_sentence
  end

  def process
    validate_file!
    statement.update!(status: "processing", error_message: nil)
    parser = parser_for_file
    if extension == "pdf" && statement.bank_name.blank? && !parser.is_a?(StatementParsers::SberbankPdf)
      statement.update!(status: "needs_bank_selection")
      return statement
    end
    statement.update!(bank_name: parser.bank_name) if statement.bank_name.blank?
    rows = parser.parse
    raise Error, "В файле не найдены транзакции." if rows.empty?

    ActiveRecord::Base.transaction do
      imported_count = 0
      duplicate_count = 0
      rows.each do |row|
        if duplicate_transaction?(statement, row)
          duplicate_count += 1
        else
          create_transaction!(statement, row)
          imported_count += 1
        end
      end
      statement.update!(
        status: "parsed",
        imported_count: imported_count,
        duplicate_count: duplicate_count,
        period_start: statement.financial_transactions.minimum(:transaction_date),
        period_end: statement.financial_transactions.maximum(:transaction_date)
      )
    end
    statement
  rescue ActiveRecord::RecordInvalid => e
    statement&.update(status: "error", error_message: e.message)
    raise Error, e.record.errors.full_messages.to_sentence
  rescue Error
    raise
  rescue StandardError => e
    statement&.update(status: "error", error_message: e.message)
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
    parser_for_file.parse
  end

  def parser_for_file
    sample = uploaded_file.tempfile.rewind && uploaded_file.tempfile.read(50_000).to_s
    uploaded_file.tempfile.rewind
    StatementParsers::Registry.for(format: extension, bank_name: statement&.bank_name, sample:, importer: self)
  end

  public

  def parse_tabular_rows
    case extension
    when "csv" then parse_csv
    when "xlsx", "xls" then parse_spreadsheet
    else []
    end
  end

  def parse_pdf_rows
    parse_pdf
  end

  private

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
    PDF::Reader.new(uploaded_file.tempfile.path).pages.flat_map do |page|
      lines = page.text.lines.map { |line| line.to_s.gsub("\u00a0", " ").strip }.reject(&:blank?)
      operation_starts = lines.each_index.select { |index| operation_start?(lines[index]) }
      operation_starts.each_with_index.filter_map do |start_index, position|
        end_index = operation_starts[position + 1] || lines.length
        parse_pdf_block(lines[start_index...end_index])
      end
    end
  rescue PDF::Reader::MalformedPDFError, ArgumentError => e
    raise Error, "PDF имеет неверный формат: #{e.message}"
  end

  def operation_start?(line)
    line.match?(/\b\d{1,2}[.\/-]\d{1,2}[.\/-]\d{4}\s+\d{1,2}:\d{2}\b/)
  end

  def parse_pdf_block(lines)
    first_line = lines.first.to_s
    date_match = first_line.match(/\b(\d{1,2}[.\/-]\d{1,2}[.\/-]\d{4})\b/)
    return unless date_match

    date = parse_date(date_match[1])
    return unless date.year.between?(2000, Date.current.year + 1)

    amount_source = first_line.gsub(/\b\d{1,2}[.\/-]\d{1,2}[.\/-]\d{4}\b/, "")
    amount_matches = amount_source.to_enum(:scan, /[+\-−]?\d[\d\s]*(?:[.,]\d{2})(?:\s*(?:₽|RUB|руб\.))?/i).map { Regexp.last_match[0] }
    unless amount_matches.any?
      amount_source = lines.join(" ").gsub(/\b\d{1,2}[.\/-]\d{1,2}[.\/-]\d{4}\b/, "")
      amount_matches = amount_source.to_enum(:scan, /[+\-−]?\d[\d\s]*(?:[.,]\d{2})(?:\s*(?:₽|RUB|руб\.))?/i).map { Regexp.last_match[0] }
    end
    return if amount_matches.empty?

    amount_token = amount_matches.first
    amount = parse_amount(amount_token)
    return if amount.zero?

    merchant = clean_pdf_merchant(lines.join(" ").delete(amount_token))
    return if merchant.blank? || merchant.match?(/\A[\d\s:.,+\-−]+\z/)

    {
      date: date,
      merchant: merchant,
      amount: amount.abs,
      transaction_type: pdf_transaction_type(merchant, amount, amount_token)
    }
  rescue Date::Error, ArgumentError
    nil
  end

  def clean_pdf_merchant(value)
    value.to_s
      .tr("\u00a0", " ")
      .gsub(/\s+/, " ")
      .gsub(/\A[\s|:;,\-−]+|[\s|:;,\-−]+\z/, "")
      .strip
  end

  def pdf_transaction_type(merchant, amount, amount_token)
    normalized = merchant.downcase
    return "income" if amount_token.match?(/\A[+]/) || normalized.match?(/зачисл|пополн|зарплат|вклад|перевод на карту/)
    return "expense" if normalized.match?(/покупк|оплат|списан|перевод на/)

    "expense"
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
    { date: parse_date(date), merchant: clean_merchant(merchant), amount: amount.abs, transaction_type: type }
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
    header.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "").strip.downcase.gsub(/[[:space:]]+/, "_")
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
    normalized = value.to_s.strip
    Date.strptime(normalized, "%d.%m.%Y")
  rescue Date::Error
    Date.strptime(normalized, "%d/%m/%Y")
  rescue Date::Error
    Date.parse(normalized)
  end

  def clean_merchant(value)
    value.to_s.gsub(/\s+/, " ").strip
  end

  def duplicate_transaction?(statement, row)
    normalized_merchant = clean_merchant(row[:merchant]).downcase
    statement.user.financial_transactions
      .joins(:bank_statement)
      .where(bank_statements: { archived: false })
      .where(transaction_date: row[:date], amount: row[:amount], transaction_type: row[:transaction_type])
      .any? { |transaction| clean_merchant(transaction.merchant).downcase == normalized_merchant }
  end

  attr_reader :statement

  def create_transaction!(statement, row)
    statement.financial_transactions.create!(
      amount: row[:amount],
      transaction_type: row[:transaction_type],
      transaction_date: row[:date],
      merchant: row[:merchant]
    ).auto_categorize!
  end
end
