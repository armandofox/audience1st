module TicketSalesImportParser
  class Goldstar

    require 'json'
    require 'csv'
    
    attr_reader :import
    delegate :raw_data, :to => :import

    def self.accept_file_type
      '.json'
    end
    
    def initialize(import)
      @import = import
      @j = nil
      @showdate = nil
      @offer_ids = []           # all offer_id's referenced in inventories
      @redemptions = {}         # Goldstar offer_id => valid_voucher
    end

    def parse
      return @import.errors.add(:base, 'Import is invalid') unless valid?
      importable_orders = []
      # A Goldstar will-call is always for exactly 1 performance
      # A will-call includes 1 or more inventories, each of which includes 1 or more offers
      # and 0 or more purchases.
      # An offer is a named ticket type and price.
      # We don't care here about separating inventories, as long as we can match the ticket
      # price within each offer.
      @j['inventories'].map { |i| i['purchases'] }.flatten.each do |purchase|
        # relevant slots: created_at, purchase_id, first_name, last_name,
        # claims (array of {quantity => x, offer_id => y})
        # Goldstar special case: a "purchase" can show up for which
        # `claims` is an empty array. This is probably a bug on their part but we have to
        # handle it.
        purchase_id,first,last = purchase.values_at('purchase_id','first_name','last_name')
        if purchase['claims'].empty?
          @import.warnings.add(:base, I18n.translate('import.goldstar.empty_claims_list',
              :purchase_id => purchase_id, :name => "#{first} #{last}"))
          next
        end
        i = ImportableOrder.new(first: purchase['first_name'], last: purchase['last_name'])
        # unfortunately we get no email from Golstar.
        # Order already imported?
        i.find_or_set_external_key purchase['purchase_id']
        populate_from_import(i, purchase) unless i.already_imported?
        importable_orders << i
      end
      importable_orders
    end

    def valid?
      valid_json?  &&  valid_show_and_showdate?  &&  valid_offers?
    end

    private

    def populate_from_import(import, purchase)
      name = "#{purchase['first_name']} #{purchase['last_name']}"
      purchase['claims'].each do |claim|
        num_seats = claim['quantity']
        offer_id = claim['offer_id']
        # does offer ID actually refer to an offer_id in this file?
        unless @redemptions.has_key?(offer_id)
          return @import.errors.add(:base, 
            I18n.translate('import.goldstar.invalid_offer_id', :offer_id => offer_id, :name => name))
        end
        redemption = @redemptions[offer_id]
        import.add_tickets(redemption, num_seats)
        import.transaction_date = Time.zone.parse purchase['created_at']
        import.set_possible_customers
        import.description << ("<br/>".html_safe) if !import.description.blank?
        import.description << "#{num_seats} @ #{redemption.show_name_with_vouchertype_name}"
      end
    end

    def valid_offers?
      # assumes valid_show_and_showdate has been called
      begin
        @j['inventories'].map { |i| i['offers'] }.flatten.each do |offer|
          @redemptions[offer['offer_id']] =
            ImportableOrder.find_valid_voucher_for(@showdate.thedate, 'Goldstar', offer['our_price'].to_f) 
        end
      rescue ImportableOrder::MissingDataError => e
        @import.errors.add(:base, e.message)
        return nil
      end
      @import.errors.empty?
    end

    def valid_show_and_showdate?
      # assumes @j has been parsed.
      import_show_name = @j['event']['title'].strip rescue 'UNKNOWN SHOW'
      import_show_name.gsub!(/^"/, '')
      import_show_name.gsub!(/"$/, '')
      begin
        thedate = Time.zone.parse(@j['on_date'] << ' ' << @j['time_note'])
      rescue ArgumentError
        @import.errors.add(:base, 'Performance date/time not found in import')
        return nil
      end
      # Check if show date exists
      @showdate = Showdate.find_by(:thedate => thedate)
      if @showdate.nil?
        @import.errors.add(:base, I18n.translate('import.showdate_not_found',
          :date => thedate.to_formatted_s(:showtime_including_year)))
        return nil
      end
      # Check if show name matches show date
      actual_show_name = @showdate.show.name
      unless ShowNameMatcher.near_match?(import_show_name, actual_show_name)
        @import.warnings.add(:base, I18n.translate('import.wrong_show',
            :performance_date => thedate.to_formatted_s(:showtime),
            :import_show => import_show_name, :actual_show => actual_show_name))
      end
      @import.errors.empty?
    end

    def valid_json?
      begin
        @j = JSON.parse(raw_data)
      rescue JSON::JSONError => e
        # is it possibly a CSV file?
        begin
          CSV.parse(raw_data)
          @import.errors.add(:base, I18n.translate('import.wrong_file_type', :type => 'CSV', :desired_type => 'JSON'))
        rescue CSV::MalformedCSVError
          @import.errors.add(:base, "Invalid JSON data: #{e.message[0..100]}")
        end
      end
      @import.errors.empty?
    end

  end
end
