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
      return false if csv_file_empty?
      begin
        csv_arr = CSV.parse(raw_data)
      rescue Exception => e
        @import.errors.add(:vendor, e)
        false
      end
      keys = ["Order #","Sale Date","Section","# of Seats","Pickup First Name","Pickup Last Name","Purchaser First Name","Purchaser Last Name","Email","Row","Start","End","Total Price","Performance Date","Zip Code"] 
      header = csv_arr[0]
      csv_arr_of_hashes = csv_arr.map {|a| Hash[ keys.zip(a) ] }
      # check if header contains required columns
      return false if csv_headers_valid?(header, keys)
      # check each row contains all required columns and are valid
      csv_arr_of_hashes.drop(1).each do |row|
        row_obj = TablelessImports::TodayTixSingleSales.new(row)
        unless row_obj.valid?
            # add errors msges
            return false
        end
      end
      true
      # if errors are found, modify the errors objecton the import itself:
      # @import.errors.add(:vendor, "Data is invalid because " + explanation_of_whats_wrong)
      # finally, return truthy value iff no errors
    end
   
    # valid helpers
    def csv_file_empty?
      if @import.raw_data.blank?
        @import.errors.add(:vendor, "Data is invalid because file is empty")
        true
      end
    end 
    
    def csv_headers_valid? header, keys
        return true if (keys-headers).length != 0
    end

   
    # parse the raw data and return an array of ImportableOrder instances
    def parse
    end
  end
end
