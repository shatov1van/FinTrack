require "rails_helper"
require "tempfile"

RSpec.describe StatementImporter do
  let(:user) { User.create!(email: "importer@fintrack.ru", password: "password123") }
  before do
    Category.create!(name: "Продукты", color: "#3b82f6", keywords: "пятерочка", is_system: true)
    Category.create!(name: "Зарплата", color: "#22c55e", keywords: "зарплата", kind: "income", is_system: true)
  end

  it "imports CSV transactions and categorizes them" do
    file = Tempfile.new([ "statement", ".csv" ])
    file.write("date,merchant,amount,transaction_type\n2026-10-01,ПЯТЕРОЧКА,-1500,expense\n2026-10-02,ЗАРПЛАТА,100000,income\n")
    file.rewind
    upload = ActionDispatch::Http::UploadedFile.new(filename: "statement.csv", type: "text/csv", tempfile: file)

    statement = described_class.call(user:, uploaded_file: upload)

    expect(statement.status).to eq("parsed")
    expect(statement.financial_transactions.count).to eq(2)
    expect(statement.financial_transactions.find_by(merchant: "ПЯТЕРОЧКА").category.name).to eq("Продукты")
  ensure
    file&.close!
  end

  it "rejects the same file for the same user" do
    file = Tempfile.new([ "statement", ".csv" ])
    file.write("date,merchant,amount\n2026-10-01,SHOP,-10\n")
    file.rewind
    upload = ActionDispatch::Http::UploadedFile.new(filename: "statement.csv", type: "text/csv", tempfile: file)
    described_class.call(user:, uploaded_file: upload)
    file.rewind

    expect { described_class.call(user:, uploaded_file: upload) }.to raise_error(StatementImporter::Error, /уже импортирован/)
  ensure
    file&.close!
  end

  it "imports CSV with common Russian headers and dates" do
    file = Tempfile.new([ "statement", ".csv" ])
    file.write("Дата операции;Описание операции;Сумма операции\n30.10.2026;Супермаркет;530,00\n")
    file.rewind
    upload = ActionDispatch::Http::UploadedFile.new(filename: "statement.csv", type: "text/csv", tempfile: file)

    statement = described_class.call(user:, uploaded_file: upload)

    expect(statement.status).to eq("parsed")
    expect(statement.financial_transactions.pluck(:merchant, :amount)).to eq([["Супермаркет", BigDecimal("530")]])
  ensure
    file&.close!
  end

  it "parses a PDF operation block without treating the balance as the amount" do
    importer = described_class.new(user:, uploaded_file: nil)

    row = importer.send(
      :parse_pdf_block,
      [
        "01.10.2026 12:34 Супермаркеты 1 234,56 3 212,76",
        "01.10.2026 117497 PYATEROCHKA 552 ROSTOV-NA-DON RUS Операция по карте ****1805"
      ]
    )

    expect(row).to include(
      date: Date.new(2026, 10, 1),
      amount: BigDecimal("1234.56"),
      transaction_type: "expense"
    )
    expect(row[:merchant]).to include("PYATEROCHKA")
  end

  it "keeps a plus sign as an income operation" do
    importer = described_class.new(user:, uploaded_file: nil)

    row = importer.send(
      :parse_pdf_block,
      [
        "29.10.2026 22:52 Перевод СБП +600,00 3 772,75",
        "29.10.2026 329885 Т-Банк. Операция по карте ****1805"
      ]
    )

    expect(row[:amount]).to eq(BigDecimal("600"))
    expect(row[:transaction_type]).to eq("income")
  end

  it "detects a PDF parser from a binary-encoded sample" do
    importer = described_class.new(user:, uploaded_file: nil)
    sample = "Т-Банк".dup.force_encoding(Encoding::ASCII_8BIT)

    parser = StatementParsers::Registry.for(
      format: "pdf",
      bank_name: nil,
      sample:,
      importer:
    )

    expect(parser).to be_a(StatementParsers::TbankPdf)
  end

  it "selects the T-Bank PDF parser" do
    importer = described_class.new(user:, uploaded_file: nil)

    parser = StatementParsers::Registry.for(
      format: "pdf",
      bank_name: "Т-Банк",
      sample: "",
      importer:
    )

    expect(parser).to be_a(StatementParsers::TbankPdf)
  end

  it "parses T-Bank PDF rows with date and time on separate lines" do
    importer = described_class.new(user:, uploaded_file: nil)

    row = importer.send(
      :parse_tbank_pdf_block,
      [
        "30.10.2026",
        "13:45",
        "30.10.2026",
        "13:46",
        "+1 500.00 ₽",
        "+1 500.00 ₽",
        "Пополнение. Система быстрых платежей",
        "4270"
      ]
    )

    expect(row).to include(
      date: Date.new(2026, 10, 30),
      amount: BigDecimal("1500"),
      transaction_type: "income"
    )
    expect(row[:merchant]).to include("Пополнение")
    expect(row[:merchant]).not_to include("4270")
  end

  it "parses T-Bank rows when dates and amounts precede the time line" do
    importer = described_class.new(user:, uploaded_file: nil)

    row = importer.send(
      :parse_tbank_pdf_block,
      [
        "30.10.2026 30.10.2026 +1500.00₽ +1500.00₽ Пополнение.Система 4270",
        "13:45 13:46 быстрыхплатежей"
      ]
    )

    expect(row).to include(
      date: Date.new(2026, 10, 30),
      amount: BigDecimal("1500"),
      transaction_type: "income"
    )
    expect(row[:merchant]).to include("Пополнение")
    expect(row[:merchant]).not_to include("4270")
  end

  it "treats a negative T-Bank top-up as an expense" do
    importer = described_class.new(user:, uploaded_file: nil)

    row = importer.send(
      :parse_tbank_pdf_block,
      [
        "20.10.2026 20.10.2026 -662.20₽ -662.20₽ Пополнение брокерского счета 4270",
        "10:00 10:01"
      ]
    )

    expect(row[:amount]).to eq(BigDecimal("662.20"))
    expect(row[:transaction_type]).to eq("expense")
  end

  it "does not classify a Sberbank expense by footer totals" do
    importer = described_class.new(user:, uploaded_file: nil)

    row = importer.send(
      :parse_pdf_block,
      [
        "01.09.2026 21:09 Супермаркеты 36,36 78,68",
        "01.09.2026 651548 MAGNIT MM LUKASHOVKA RUS. Операция по карте ****8593",
        "Продолжение на следующей странице",
        "Пополнение 61 408,00",
        "Списание 61 523,04"
      ]
    )

    expect(row[:amount]).to eq(BigDecimal("36.36"))
    expect(row[:transaction_type]).to eq("expense")
    expect(row[:merchant]).to include("MAGNIT")
    expect(row[:merchant]).not_to include("Пополнение")
  end

  it "keeps identical merchants and amounts when operation times differ" do
    importer = described_class.new(user:, uploaded_file: nil)

    first = {
      date: Date.new(2026, 10, 6), transaction_time: "10:00:00",
      merchant: "DONATOV.NET", amount: BigDecimal("275"), transaction_type: "expense"
    }
    second = first.merge(transaction_time: "11:00:00")

    expect(importer.send(:duplicate_transaction?, BankStatement.new(user:), first)).to be(false)
    statement = BankStatement.create!(user:, bank_name: "Т-Банк", file_name: "statement.pdf", status: "parsed")
    statement.financial_transactions.create!(
      transaction_date: first[:date],
      transaction_time: first[:transaction_time],
      merchant: first[:merchant],
      amount: first[:amount],
      transaction_type: first[:transaction_type]
    )
    expect(importer.send(:duplicate_transaction?, statement, second)).to be(false)
    expect(importer.send(:duplicate_transaction?, statement, first)).to be(true)
  end
end
