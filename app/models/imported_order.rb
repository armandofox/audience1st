class ImportedOrder < Order

  belongs_to :ticket_sales_import
  
  # This subclass captures the abstraction of "an order that is almost ready to be imported,
  # once we ascertain which customer should get it".  In addition to the regular Order fields:
  #   - ImportedOrder has a serialized hash from_import[] that captures the data about this
  #     order as parsed from the original import file
  #   -  ...including info about which customer(s) the order COULD be imported to when finalized
  #   - Specifically belongs_to a ticket_sales_import
  #   - Validates the presence and uniqueness of external_key (vendor's order ID)
  
  # A +TicketSalesImportParser+ should do the following for each order in the will-call file.
  # Every step that calls
  #   an instance method on +ImportedOrder+ may raise +ImportableOrder::MissingDataError+.
  #   2. Call +#find_or_set_external_key+ with the vendor's order number
  #   3. If the above call results in the +action+ attribute set to +ALREADY_IMPORTED+, we're done
  #   4. Otherwise call +#find_valid_voucher_for+ with the performance date as a +Time+, the
  #      vendor name as a string (to help find the +ValidVoucher+), and price per ticket as float.
  #   5. If a +ValidVoucher+ is returned, call +Order#add_tickets+ on the +ImportableOrder+'s
  #      associated +Order+ passing that +ValidVoucher+ and the number of seats of that type.
  #   6. Call +#set_possible_customers+ to determine who the order might be imported to.
  #   7. Set +description+ to something human-friendly shown in the import view.
  #   8. Add this +ImportableOrder+ to an array.
  # When all orders in a will-call file have been processed as above, return the array of
  # unpersisted +ImportedOrder+ objects.

  class MissingDataError < StandardError ;  end

  validates_presence_of :external_key
  validates_uniqueness_of :external_key, :allow_blank => true, conditions: -> { where.not(:sold_on => nil) }

  serialize :from_import
  after_initialize :initialize_import_info

  class ImportInfo
    attr_accessor :transaction_date, :first, :last, :email, :customer_ids, :action, :description, :must_use_existing_customer
    def initialize(args={})
      args.each_pair { |k,v| self.public_send("#{k}=", v) }
    end
    def set_possible_customers
      if (! email.blank?  && (c = Customer.find_by_email(email)))
        # unique match
        self.customer_ids = [c.id]
        self.must_use_existing_customer = true
      else
        self.customer_ids = Customer.possible_matches(first,last,email).map(&:id)
        self.must_use_existing_customer = false
      end
      self
    end
  end

  private
  
  def initialize_import_info
    self.from_import ||= ImportInfo.new
  end

  public
  
  def self.find_valid_voucher_for(thedate,vendor,price)
    showdate = Showdate.where(:thedate => thedate).first
    price = price.to_f
    raise MissingDataError.new(I18n.translate('import.showdate_not_found', :date => thedate.to_formatted_s(:showtime_including_year))) if showdate.nil?
    vouchertype = Vouchertype.where("name LIKE ?", "%#{vendor}%").find_by(:season => showdate.season, :price => price, :offer_public => Vouchertype::EXTERNAL)
    raise MissingDataError.new(I18n.translate('import.vouchertype_not_found',
        :season => Option.humanize_season(showdate.season),
        :vendor => vendor, :price => sprintf('%.02f', price))) if vouchertype.nil?
    redemption = ValidVoucher.find_by(:vouchertype => vouchertype, :showdate => showdate)
    raise MissingDataError.new(I18n.translate('import.redemption_not_found',
        :vouchertype => vouchertype.name,:performance => showdate.printable_name)) if redemption.nil?
    redemption
  end

  # Delegates the actual work to the Order, but keeps track of ticket count per valid-voucher
  # DELETEME
  def add_tickets(vv, num)
    if vv.showdate.has_reserved_seating?
      # put in "placeholder" seat numbers
      # BUG::This will screw up seatmap display!!
      self.add_tickets_without_capacity_checks(vv, num, Array.new(num) { Voucher::PLACEHOLDER })
    else
      self.add_tickets_without_capacity_checks(vv, num)
    end
    raise MissingDataError.new("Cannot add tickets to order: #{order.errors.full_messages.join(', ')}") unless errors.empty?
    self.valid_vouchers[vv] += num
  end

end
