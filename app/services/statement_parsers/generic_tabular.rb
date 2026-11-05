module StatementParsers
  class GenericTabular < Base
    def bank_name
      "Другой"
    end

    def parse
      importer.parse_tabular_rows
    end
  end
end
