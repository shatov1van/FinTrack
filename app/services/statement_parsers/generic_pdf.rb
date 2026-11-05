module StatementParsers
  class GenericPdf < Base
    def parse
      importer.parse_pdf_rows
    end
  end
end
