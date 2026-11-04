module StatementParsers
  class TbankPdf < Base
    def bank_name
      "Т-Банк"
    end

    def detect?(sample)
      sample.match?(/т-?банк|t-?bank|tinkoff/i)
    end

    def parse
      importer.parse_tbank_pdf_rows
    end
  end
end
