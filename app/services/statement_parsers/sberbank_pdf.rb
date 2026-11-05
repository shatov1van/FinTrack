module StatementParsers
  class SberbankPdf < Base
    def bank_name
      "Сбербанк"
    end

    def detect?(sample)
      sample.match?(/Сбербанк|СБЕРБАНК|ПАО Сбербанк/i)
    end

    def parse
      importer.parse_pdf_rows
    end
  end
end
