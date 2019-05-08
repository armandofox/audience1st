module TicketSalesImportParser
  class TodayTix

    attr_reader :import
    delegate :raw_data, :to => :import

    class MissingDataError < StandardError ; end

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
      importable_orders = []
      begin
        orders_as_hash.each do |h|
          redemption = find_valid_voucher_for(h)
          imp_ord = ImportableOrder.new
          imp_ord.customers = Customer.possible_matches(h["Purchaser First Name"], h["Purchaser Last Name"])
          imp_ord.order.add_tickets(redemption, order_hash["# of Seats"])
          importable_orders << imp_ord
        end
        importable_orders
      rescue MissingDataError
        []
      end
    end

    def orders_as_hash          # :nodoc:
      CSV.parse(raw_data, :headers => true).map(&:to_hash)
    end

    def find_valid_voucher_for(h)   # :nodoc:
      showdate = Showdate.find_by(:thedate => Time.zone.parse(h["Performance Date"] ))
      num_seats = h["# of Seats"].to_i
      price_per_seat = h["Total Price"].to_f / num_seats
      vouchertype = Vouchertype.
        where("name LIKE ?", import.vendor).
        find_by(:season => showdate.season, :price => price_per_seat)
      if vouchertype.nil?
        import.errors.add(:base, t('import.vouchertype_not_found', :season => showdate.season,
            :vendor => import.vendor, :price => sprintf('%.02f', price_per_seat)))
        raise MissingDataError
      end
      redemption = ValidVoucher.find_by(:vouchertype => vouchertype, :showdate => showdate).first
      if redemption.nil?
        import.errors.add(:base, t('import.redemption_not_found', :vouchertype => vouchertype.name,
            :performance => showdate.printable_name))
        raise MissingDataError
      end
    end
  end
end
