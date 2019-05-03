module TicketSalesImportParser
  class TodayTix
    require 'csv'
    attr_reader :import
    delegate :raw_data, :to => :import
    
    def initialize(import)
      @import = import
    end

    # sanity-check that the raw data appears to be a valid import file
    def valid?
      #byebug 
      
      # Check if CSV file is empty
      if @import.raw_data.blank?
        @import.errors.add(:vendor, "Data is invalid because file is empty")
        false
      end
        
      begin
        csv_arr = CSV.parse(raw_data)
      rescue Exception => e
        @import.errors.add(:vendor, e)
        false
      end
    
      # Check if csv file contains nil or multiple words per entry

      csv_arr.each do |row|
          return false if row.include?(nil)
          row.each do |entry|
              return false if entry.split(' ').length > 1
          end
      end
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
