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
end
