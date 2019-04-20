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
      # if errors are found, modify the errors objecton the import itself:
      # @import.errors.add(:vendor, "Data is invalid because " + explanation_of_whats_wrong)
      # finally, return truthy value iff no errors
    end

    # parse the raw data and return an array of ImportableOrder instances
    def parse
    end
  end
end
