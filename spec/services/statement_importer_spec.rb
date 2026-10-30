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

    expect(statement.status).to eq("completed")
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
end
