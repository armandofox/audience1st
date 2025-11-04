class ImportedOrder < Order

  def haml_object_ref ; 'order' ; end # so Haml treats as parent class when creating view elts
  
  belongs_to :ticket_sales_import, optional: true
  
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
  validates_presence_of :processed_by
  
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
    self.purchasemethod = Purchasemethod.get_type_by_name 'ext'
  end

  
  public

  def self.sorted_by_import_customer
    all.to_a.sort { |o1,o2|  o1.from_import.last <=> o2.from_import.last  }
  end

  def finalize(for_customer, by_user)
    io = self.from_import
    sold_on = io.transaction_date
    # if a non-nil customer ID is specified, assign to that customer; else create new
    cid = customer_for[self.id.to_s].to_i
    if (cid != 0)
      self.finalize_with_existing_customer_id!(cid, current_user, sold_on)
      @import.existing_customers += 1
    else                  # create new customer
      customer = Customer.new(:first_name => io.first, :last_name => io.last,
                              :email => io.email, :ticket_sales_import => @import)
      self.finalize_with_new_customer!(customer, current_user, sold_on)
      @import.new_customers += 1
    end
    @import.tickets_sold += self.ticket_count
    @import.completed = true
    @import.save!
  end
  
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

end
