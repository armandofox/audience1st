module TicketSalesImportParser
  class TodayTix

    attr_reader :import
    delegate :raw_data, :to => :import
    
    def initialize(import)
      @import = import
    end

    # sanity-check that the raw data appears to be a valid import file
    def valid?
      true
    end

  end
end
