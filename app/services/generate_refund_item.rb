module GenerateRefundItem

  class Parser
    attr_accessor :str, :orig_price, :desc, :who_when
    def initialize(str)
      @str = str
      @orig_price = 0
      parse_other_fields
    end
    
    def self.check_all(tenant)
      Apartment::Tenant.switch!(tenant)
      c = CanceledItem.all
      failed = []
      c.each do |item|
        begin
          p = Parser.new(c.comments)
        rescue StandardError => e
          failed << "[#{c.id}] c.comments"
        end
      end
      puts "#{failed.size} failed out of #{c.size}"
      failed.each { |f| puts f}
    end

    def parse_other_fields
      # Canceled item's description looks like:
      #   [CANCELED Armando Fox 2019-12-31-xx:xx] description
      # where description looks like:
      # - Vouchers: "25.00 General Adm (Dreamgirls) [99999]"
      # - Donation: "25.00 History Fund donation [99999]"
      # - Retail:  "15.00 Altarena shirt  [99999]"
      # eg: [CANCELED Super Administrator October 20, 2019 18:43] 35.00 General (Rent, the musical with the really long 61 character long name - Friday, Oct 11, 8:00 PM) [1763]
      rx = /\[CANCELED ([^\]]+)\] (\d+\.\d\d) (.*) \[\d+\]$/
      if rx =~ @str
        @who_when = $1
        @orig_price = $2.to_f
        @desc = $3 
      else
        raise "Cannot parse fields from <#{@str}>"
      end
    end
  end

  class Migrator
    attr_accessor :attr
    def initialize(canceled_item)
      @item = canceled_item
      @attr = Parser.new(canceled_item.comments)
    end
    def refundable?
      attr.orig_price > 0.0 && @item.finalized?
    end

    def generate_attributes
      fields_to_copy = %w(customer_id vouchertype_id processed_by_id bundle_id account_code_id order_id) 
      refund = RefundItem.new()
    end

  end
end
