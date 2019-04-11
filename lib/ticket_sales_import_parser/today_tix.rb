module TicketSalesImportParser
  class TodayTix

    attr_reader :import
    delegate :raw_data, :to => :import
    
    def initialize(import)
      @import = import
    end

    def parse_metadata
      
    end

  end
end
