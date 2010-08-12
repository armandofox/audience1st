class TicketSalesImport < Import

  belongs_to :show
  validates_associated :show
  validate :show_exists?

  class TicketSalesImport::ShowNotFound < Exception ; end
  class TicketSalesImport::PreviewOnly  < Exception ; end
  class TicketSalesImport::ImportError < Exception ; end

  attr_accessor :vouchers, :existing_vouchers
  attr_accessor :created_customers, :matched_customers
  attr_accessor :created_showdates, :created_vouchertypes

  public

  def show_exists?
    errors.add_to_base('You must specify an existing show.')  and return nil unless  self.show_id && Show.find_by_id(show_id)
    true
  end    

  def show_name ;   show_exists? ? show.name : '???'  ;  end
  
  def preview
    Customer.disable_email_sync
    do_import(false)
    Customer.enable_email_sync
    messages << "This result doesn't seem right.  You may want to cancel the import unless you're sure this is what you expect." unless sanity_check
    []
  end

  def import! ;  [do_import(true), []] ;   end

  def valid_records ; number_of_records ; end
  def invalid_records ; 0 ; end

  protected

  def sanity_check ; nil ; end

  def self.col_index(letters)
    letters = letters.to_s.downcase.split('')
    letters.length == 1 ?
    letters[0].ord - 97 :
      26 * (letters[0].ord - 96) + (letters[1].ord - 97)
  end
  def col_index(letters) ; TicketSalesImport.col_index(letters) ; end
  
  def after_initialize          # called after AR::Base makes a new obj
    self.messages ||= []
    self.messages << "Show: #{show.name}" if show
    self.vouchers = []
    self.created_customers = []
    self.matched_customers = []
    self.created_showdates = []
    self.created_vouchertypes = []
    self.existing_vouchers = 0
  end

  def do_import(really_import=false)
    begin
      return [] unless show_exists?
      transaction do
        get_ticket_orders
        show.adjust_metadata_from_showdates
        messages << "House capacity adjusted to #{show.house_capacity} (was #{show.house_capacity_was})" if show.house_capacity_changed?
        messages << "Run dates adjusted to #{show.run_dates}" if
            (show.opening_date_changed? || show.closing_date_changed?)
        # all is well!  Roll back the transaction and report results.
        raise TicketSalesImport::PreviewOnly unless really_import
        # finalize other changes
        @created_customers.each { |customer| customer.save! }
        self.show.save!             # save new show and showdates too
        self.save!
      end
    rescue CSV::IllegalFormatError
      self.errors.add_to_base("Format error in .CSV file.  If you created this file on a Mac, be sure it's saved as Windows CSV.")
    rescue TicketSalesImport::PreviewOnly
      ;
    rescue TicketSalesImport::ShowNotFound
      self.errors.add_to_base("Couldn't find production name to associate with import")
    rescue TicketSalesImport::ImportError => e
      self.errors.add_to_base(e.message)
    rescue Exception => e
      self.errors.add_to_base("Unexpected error: #{e.message}")
      RAILS_DEFAULT_LOGGER.info "Importing id #{self.id} at record #{self.number_of_records}: #{e.message}\n#{e.backtrace}"
    end
    @vouchers
  end
  
  def import_customer(row,args)
    attribs = {}
    [:first_name, :last_name, :street, :city, :state, :zip, :day_phone, :email].each do |attr|
      # special case: "N/A" is same as blank
      attribs[attr] = row[args[attr]] if (args.has_key?(attr)  && row[args[attr]] != 'N/A')
    end
    customer = Customer.new(attribs)
    customer.force_valid = customer.created_by_admin = true
    if (existing = Customer.find_unique(customer))
      customer = Customer.find_or_create!(customer) # to update other attribs
      self.matched_customers << customer unless
        (self.matched_customers.include?(customer) ||
        self.created_customers.include?(customer))
    else
      customer = Customer.find_or_create!(customer)
      self.created_customers << customer
    end
    customer
  end

  def import_showdate(time_as_str)
    event_date = Time.parse(time_as_str)
    unless (self.show.showdates &&
        sd = self.show.showdates.detect { |sd| sd.thedate == event_date })
      sd = Showdate.placeholder(event_date)
      self.created_showdates << sd
      self.show.showdates << sd
    end
    sd
  end

  def already_entered?(order_id)
    return nil unless (v = Voucher.find_by_external_key(order_id))
    # this voucher's already been entered.  make sure show name matches!!
    raise(TicketSalesImport::ImportError,
      "Existing order #{order_id} was already entered, but for a different show (#{v.show.name}, show ID #{v.show.id})") if v.show.id != self.show_id
    true
  end

end
