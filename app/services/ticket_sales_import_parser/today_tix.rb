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
      map_keys_to_sym = ["Order #" => :order_num,"Sale Date" => :sale_date ,"Section" => :section,"# of Seats" => :seat_nums,"Pickup First Name" => :pickup_first_name,"Pickup Last Name" => :pickup_last_name,"Purchaser First Name" => :purchaser_first_name,"Purchaser Last Name" => :purchaser_last_name,"Email" => :email,"Row" => :row,"Start" => :start,"End" => :end,"Total Price" => :total_price,"Performance Date" => :performance_date,"Zip Code" => :zipcode] 

      header = csv_arr[0]
      # check if header contains required columns
      return false if csv_headers_valid?(header, keys) 

      # convert header strings into symbols
      header_sym = header.map { |x| map_keys_to_sym[x] }

      csv_arr_of_hashes = csv_arr.map {|a| Hash[ header_sym.zip(a) ] }
     # check each row contains all required columns and are valid
      csv_arr_of_hashes.drop(1).each do |row|
        row_obj = TablelessImports::TodayTixSingleSales.new(row)
        unless row_obj.valid?
            row_obj.errors.full_messages.each do |err_msg|
                # add error messeges
                @import.errors.add(:vendor, "Data is invalid because " + err_msg )
            end
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
