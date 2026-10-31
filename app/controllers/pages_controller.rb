class PagesController < ApplicationController
  BANK_SIGNATURES = {
    "Сбербанк" => /сбербанк|sberbank/i,
    "Т-Банк" => /т-?банк|t-?bank|tinkoff/i,
    "Альфа-Банк" => /альфа.?банк|alfa.?bank/i,
    "ВТБ" => /\bвтб\b|\bvtb\b/i,
    "Газпромбанк" => /газпромбанк|gazprombank/i,
    "Райффайзенбанк" => /райффайзен|raiffeisen/i,
    "Россельхозбанк" => /россельхозбанк|rshb/i,
    "Совкомбанк" => /совкомбанк|sovcombank/i,
    "МКБ" => /\bмкб\b|moscow credit/i,
    "Росбанк" => /росбанк|rosbank/i
  }.freeze

  before_action :authenticate_user!, only: :import

  def home
    return unless user_signed_in?

    @user = current_user
    @from = parse_date(params[:from]) || Date.current.beginning_of_month
    @to = parse_date(params[:to]) || Date.current
    @bank_name = params[:bank_name].presence
    @transactions = filtered_transactions
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    @recent_transactions = @transactions.includes(:category).order(transaction_date: :desc).limit(10).offset((@page - 1) * 10)
    @has_next_page = @transactions.offset(@page * 10).exists?
    @total_income = @transactions.where(transaction_type: "income").sum(:amount)
    @total_expenses = @transactions.where(transaction_type: "expense").sum(:amount)
    @category_totals = @transactions.where(transaction_type: "expense").group("categories.name").joins(:category).sum(:amount).sort_by { |_name, amount| -amount }
  end

  def import
    return unless request.post?

    validate_upload!
    statement = current_user.bank_statements.create!(
      bank_name: params[:bank_name].presence || detect_bank(params[:statement_file]),
      file_name: params[:statement_file].original_filename,
      file_digest: Digest::SHA256.file(params[:statement_file].tempfile.path).hexdigest,
      source_format: File.extname(params[:statement_file].original_filename).delete(".").downcase,
      status: "pending"
    )
    statement.source_file.attach(params[:statement_file])
    ParseStatementJob.perform_later(statement)
    redirect_to import_path, notice: "Выписка принята в обработку."
  rescue StatementImporter::Error => e
    redirect_to import_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to import_path, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def validate_upload!
    StatementImporter.new(user: current_user, uploaded_file: params[:statement_file]).send(:validate_file!)
    digest = Digest::SHA256.file(params[:statement_file].tempfile.path).hexdigest
    raise StatementImporter::Error, "Этот файл уже импортирован." if current_user.bank_statements.exists?(file_digest: digest)
  end

  def filtered_transactions
    current_user.financial_transactions
      .joins(:bank_statement)
      .where(bank_statements: { archived: false })
      .then { |scope| @bank_name ? scope.where(bank_statements: { bank_name: @bank_name }) : scope }
      .where(transaction_date: @from..@to)
  end

  def detect_bank(uploaded_file)
    filename = utf8_text(uploaded_file.original_filename)
    BANK_SIGNATURES.each { |bank, signature| return bank if filename.match?(signature) }

    extension = File.extname(filename).downcase
    if %w[.csv .txt].include?(extension)
      sample = utf8_text(File.binread(uploaded_file.tempfile.path).byteslice(0, 10_000))
      return BANK_SIGNATURES.find { |_bank, signature| sample.match?(signature) }&.first || "Другой"
    end
    return unless extension == ".pdf"

    sample = utf8_text(PDF::Reader.new(uploaded_file.tempfile.path).pages.first&.text.to_s.first(10_000))
    BANK_SIGNATURES.find { |_bank, signature| sample.match?(signature) }&.first
  rescue PDF::Reader::MalformedPDFError, ArgumentError, EncodingError
    nil
  end

  def utf8_text(value)
    value.to_s.force_encoding(Encoding::UTF_8).scrub
  end

  def parse_date(value)
    Date.parse(value.to_s) if value.present?
  rescue Date::Error
    nil
  end
end
