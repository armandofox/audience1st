module TicketSalesImportParser
  class TodayTix
    
    require 'csv'

    attr_reader :import
    delegate :raw_data, :to => :import

    class MissingDataError < StandardError ; end

    # columns that must be nonblank in body
    REQUIRED_COLUMNS = ["Order #", "Sale Date", "Email",
      "Pickup First Name","Pickup Last Name","Purchaser First Name","Purchaser Last Name",
      "# of Seats","Total Price","Performance Date"].freeze
    # columns that might be blank in body, but must be present in header
    OTHER_COLUMNS = ["Row","Start","End","Zip Code"].freeze
    COLUMNS = (REQUIRED_COLUMNS + OTHER_COLUMNS).freeze

    def self.accept_file_type
      '.csv'
    end

    def initialize(import)
      @import = import
      @index = 0
      @csv = nil
    end

    # parse the raw data and add ImportedOrder instances to Import object
    def parse
      csv_file_parsable? unless @csv # make sure we have parsed it even if #valid? wasn't 
      begin
        Order.transaction do
          @csv.map(&:to_hash).each do |h|
            order = ImportedOrder.create!(:external_key => h["Order #"], :processed_by => @import.processed_by)
            populate_from_import(order, h)
            @import.imported_orders << order
          end
        end
      rescue ImportedOrder::MissingDataError => e
        import.errors.add(:base, e.message)
        return nil
      end
    end

    # sanity-check that the raw data appears to be a valid import file
    def valid?
      csv_file_parsable?  &&  required_headers_present?  &&  rows_valid?
    end

    private                     # helper methods below here

    def populate_from_import(order,h)
      num_seats = h["# of Seats"].to_i
      price_per_seat = h["Total Price"].to_f / num_seats
      redemption = ImportedOrder.find_valid_voucher_for(Time.zone.parse(h["Performance Date"]), 'TodayTix', price_per_seat)
      order.add_tickets_without_capacity_checks(redemption, num_seats)
      import_info = ImportedOrder::ImportInfo.new(
        :transaction_date => Time.zone.parse(h["Sale Date"]),
        :description => "#{num_seats} @ #{redemption.show_name_with_vouchertype_name}",
        :first => h["Purchaser First Name"],
        :last => h["Purchaser Last Name"],
        :email => h["Email"])
      import_info.set_possible_customers
      order.from_import = import_info
      unless ShowNameMatcher.near_match?(redemption.showdate.name, h["show"])
        import.warnings.add(:base, I18n.translate('import.wrong_show',
            :import_show => h["show"], :actual_show => redemption.showdate.name,
            :performance_date => redemption.thedate.to_formatted_s(:showtime)))
      end
    end

    def error(msg)
      @import.errors.add(:base, "#{msg} on row #{@index.to_i}")
    end

    def csv_file_parsable?
      begin
        @csv = CSV.parse(raw_data, :headers => true, :converters => lambda { |f| f.to_s.strip })
        error("File is empty") if @csv.empty?
        !@csv.empty?
      rescue CSV::MalformedCSVError => e
        error("Invalid CSV file: #{e.message}")
        false
      end
    end

    def required_headers_present?
      missing = COLUMNS - @csv[0].to_h.keys
      error("Required column(s) #{missing.join(', ')} are missing") unless missing.empty?
      missing.empty?
    end

    def rows_valid?
      @csv.each_with_index do |row,num|
        @index = num+2
        valid_row?(row)
      end
      @import.errors.empty?
    end

    def valid_row?(row)
      # all required (nonblank) columns are nonblank...
      error("some required columns are blank") unless
        REQUIRED_COLUMNS.all? { |col|  !(row[col].blank?) }
      error("Order number is invalid") unless row["Order #"] =~ /\S+/
      error("Sale Date is invalid") unless valid_date?(row["Sale Date"])
      error("Performance Date is invalid") unless valid_date?(row["Performance Date"])
      error("Price is invalid") unless row["Total Price"] =~ /^[0-9.]+$/
      error("Total # of seats is invalid") unless row["# of Seats"].to_i > 0
      error("Email is invalid") unless row["Email"] =~ /[^@]@[^@]/
    end

    def valid_date?(date)
      Time.zone.parse(date) rescue nil
    end

  end
end
