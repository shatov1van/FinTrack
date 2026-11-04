module StatementParsers
  class Registry
    ADAPTERS = [ SberbankPdf, TbankPdf, GenericPdf, GenericTabular ].freeze

    def self.for(format:, bank_name:, sample:, importer:)
      sample = sample.to_s.force_encoding(Encoding::UTF_8).scrub
      return SberbankPdf.new(importer) if format == "pdf" && bank_name.to_s.match?(/сбер|sber/i)
      return SberbankPdf.new(importer) if format == "pdf" && sample.to_s.match?(/сбербанк|сбербанк онлайн|пao сбербанк/i)
      return TbankPdf.new(importer) if format == "pdf" && bank_name.to_s.match?(/т-?банк|t-?bank|tinkoff/i)
      return TbankPdf.new(importer) if format == "pdf" && sample.to_s.match?(/т-?банк|t-?банк|tinkoff/i)
      return GenericPdf.new(importer) if format == "pdf"

      GenericTabular.new(importer)
    end
  end
end
