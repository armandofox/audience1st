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
    OTHER_COLUMNS = ["Section","Row","Start","End","Zip Code"].freeze
    COLUMNS = (REQUIRED_COLUMNS + OTHER_COLUMNS).freeze

    def initialize(import)
      @import = import
    end

    # parse the raw data and return an array of ImportableOrder instances
    def parse
      importable_orders = []
      begin
        orders_as_hash.each do |h|
          redemption = find_valid_voucher_for(h)
          imp_ord = ImportableOrder.new
          first,last = h.values_at("Purchaser First Name", "Purchaser Last Name")
          imp_ord.import_first_name = first
          imp_ord.import_last_name = last
          imp_ord.import_email = h["Purchaser Email"]
          imp_ord.customers = Customer.possible_matches(first,last,imp_ord.import_email)
          imp_ord.order.external_key = h["Order #"]
          num_seats = h["# of Seats"].to_i
          imp_ord.order.add_tickets(redemption, num_seats)
          imp_ord.description = "#{num_seats} @ #{redemption.show_name_with_vouchertype_name}"
          importable_orders << imp_ord
        end
      rescue MissingDataError
        []
      end
      importable_orders
    end

    def orders_as_hash          # :nodoc:
      CSV.parse(raw_data, :headers => true).map(&:to_hash)
    end

    def find_valid_voucher_for(h)   # :nodoc:
      thedate = Time.zone.parse(h["Performance Date"] )
      showdate = Showdate.where(:thedate => thedate).first
      if showdate.nil?
        import.errors.add(:base, I18n.translate('import.showdate_not_found', :date => thedate.to_formatted_s(:showtime_including_year)))
        raise MissingDataError
      end
      num_seats = h["# of Seats"].to_i
      price_per_seat = h["Total Price"].to_f / num_seats
      vouchertype = Vouchertype.
        where("name LIKE ?", "%#{import.vendor}%").
        find_by(:season => showdate.season, :price => price_per_seat)
      if vouchertype.nil?
        import.errors.add(:base, I18n.translate('import.vouchertype_not_found',
            :season => ApplicationController.helpers.humanize_season(showdate.season),
            :vendor => import.vendor, :price => sprintf('%.02f', price_per_seat)))
        raise MissingDataError
      end
      redemption = ValidVoucher.find_by(:vouchertype => vouchertype, :showdate => showdate)
      if redemption.nil?
        import.errors.add(:base, I18n.translate('import.redemption_not_found', :vouchertype => vouchertype.name,
            :performance => showdate.printable_name))
        raise MissingDataError
      end
      redemption
    end
    
    # sanity-check that the raw data appears to be a valid import file
    def valid?
      csv_file_parsable?  &&  required_headers_present?  &&  rows_valid?
    end

    private                     # helper methods below here

    def csv_file_parsable?
      begin
        @csv = CSV.parse(raw_data, :headers => true)
        @import.errors.add(:base, "File is empty") if @csv.empty?
        @csv.empty?
      rescue CSV::MalformedCSVError => e
        @import.errors.add(:base, "File format is invalid: #{e.message}")
        false
      end
    end

    def required_headers_present?
      missing = COLUMNS - @csv[0].to_h.keys
      unless missing.empty?
        @import.errors.add(:base, "Required column(s) are missing: #{missing}")
      end
      missing.empty?
    end

    def rows_valid?
      @csv.drop(1).each_with_index do |row,num|
        byebug
        unless valid_row?(row)
          @import.errors.add(:base, "Row #{num+1} invalid: #{row}")
          return false 
        end
      end
    end

    def valid_row?(row)
      # all required (nonblank) columns are nonblank...
      REQUIRED_COLUMNS.all? { |col|  !(row[col].blank?) }  &&
        valid_date?(row["Sale Date"])                      && # date columns look like dates
        valid_date?(row["Performance Date"])               &&
        row["Total Price"].to_f > 0.0                      && # total price looks like a number
        row["# of Seats"].to_i > 0                         && # of seats looks like a number
        row["Email"] =~ /[^@]@[^@]/                           # minimally valid email
    end

    def valid_date?(date)
      begin
        Time.zone.parse(date)
        true
      rescue ArgumentError
        false
      end
    end

  end
end
