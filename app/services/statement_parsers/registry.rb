module StatementParsers
  class Registry
    ADAPTERS = [ SberbankPdf, GenericPdf, GenericTabular ].freeze

    def self.for(format:, bank_name:, sample:, importer:)
      return SberbankPdf.new(importer) if format == "pdf" && bank_name.to_s.match?(/сбер|sber/i)
      return SberbankPdf.new(importer) if format == "pdf" && sample.to_s.match?(/сбербанк|сбербанк онлайн|пao сбербанк/i)
      return GenericPdf.new(importer) if format == "pdf"

      GenericTabular.new(importer)
    end
  end
end
