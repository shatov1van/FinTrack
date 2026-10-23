class FinancialTransaction < ApplicationRecord
  belongs_to :bank_statement
  belongs_to :category
end
