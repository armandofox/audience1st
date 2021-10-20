module TicketSalesImportParser
  class Goldstar

    require 'json'
    require 'csv'
    
    attr_reader :import
    delegate :raw_data, :to => :import

    def self.accept_file_type
      '.json'
    end

    def valid?
      valid_json?  &&  valid_show_and_showdate?  &&  valid_offers?
    end

    def initialize(import)
      @import = import
      @j = nil
      @showdate = nil
      @offer_ids = []           # all offer_id's referenced in inventories
      @redemptions = {}         # Goldstar offer_id => valid_voucher; set by #valid_offers?
    end

    def parse
      unless valid?
        return @import.errors.add(:base, 'Import is invalid')
      end
      # A Goldstar will-call is always for exactly 1 performance
      # A will-call includes 1 or more inventories, each of which includes 1 or more offers
      #   and 0 or more purchases for each offer type.
      # An offer is a named ticket type and price.
      # We don't care here about separating inventories, as long as we can match the ticket
      # price within each offer.
      begin
        Order.transaction do      # create all temporary orders, or none
          @j['inventories'].map { |i| i['purchases'] }.flatten.each do |purchase|
            purchase_id,first,last,date,claims = purchase.values_at('purchase_id','first_name','last_name','created_at','claims')
            # Goldstar bug: a `purchase` can show up with empty `claims` set; must handle gracefully
            if purchase['claims'].empty?
              @import.warnings.add(:base, I18n.translate('import.goldstar.empty_claims_list',
                                                         :purchase_id => purchase_id, :name => "#{first} #{last}"))
              next
            end
            # claims: array of {quantity => x, offer_id => y} for each offer_id (redemption)
            description = []
            import_params = ImportedOrder::ImportInfo.new(
              :first => first, :last => last, :transaction_date => Time.zone.parse(date))
            import_params.set_possible_customers
            order = ImportedOrder.create(:external_key => purchase_id, :from_import => import_params)
            purchase['claims'].each do |claim|
              num_seats,offer_id = claim.values_at('quantity', 'offer_id')
              # does offer ID actually refer to an offer_id in this file?
              unless @redemptions.has_key?(offer_id)
                return @import.errors.add(:base, I18n.translate('import.goldstar.invalid_offer_id', :offer_id => offer_id, :name => "#{first} #{last}"))
              end
              redemption = @redemptions[offer_id]
              description << "#{num_seats} @ #{redemption.show_name_with_vouchertype_name}"
              order.add_tickets_without_capacity_checks(redemption, num_seats)
            end
            order.from_import.description = description.join('<br/>').html_safe
            order.save!
            @import.imported_orders += order
          end
        end
      rescue RuntimeError => e
        @import.errors.add(:base, "Unexpected import error: #{e.message}")
      end
    end
    
    private

    def valid_offers?
      # assumes valid_show_and_showdate has been called
      begin
        @j['inventories'].map { |i| i['offers'] }.flatten.each do |offer|
          @redemptions[offer['offer_id']] =
            ImportedOrder.find_valid_voucher_for(@showdate.thedate, 'Goldstar', offer['our_price'].to_f) 
        end
      rescue ImportedOrder::MissingDataError => e
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
