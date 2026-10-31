module StatementParsers
  class Base
    attr_reader :importer

    def initialize(importer)
      @importer = importer
    end

    def detect?(_sample)
      false
    end

    def bank_name
      nil
    end

    def parse
      raise NotImplementedError
    end
  end
end
