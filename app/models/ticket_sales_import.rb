class TicketSalesImport < Import

  belongs_to :show
  validates_associated :show

  class TicketSalesImport::ShowNotFound < Exception ; end
  class TicketSalesImport::PreviewOnly  < Exception ; end

  attr_accessor :show, :vouchers, :existing_vouchers, :num_records
  attr_accessor :created_customers, :matched_customers
  attr_accessor :created_showdates, :created_vouchertypes

  public

  def preview
    return [] unless show_valid?
    Customer.disable_email_sync
    do_import(false)
    Customer.enable_email_sync
    []
  end

  def import!
    show_valid? ? [do_import(true), []] : [ [],[] ]
  end

  def valid_records ; num_records ; end
  def invalid_records ; 0 ; end

  protected

  def show_valid?
    if show && Show.find_by_id(show)
      return true
    else
      errors.add_to_base 'You must specify a show.'
      return nil
    end
  end

  def initialize_import
    @show = nil
    @show_was_created = nil
    @vouchers = []
    @created_customers = []
    @matched_customers = []
    @created_showdates = []
    @created_vouchertypes = []
    @existing_vouchers = 0
    @num_records = 0
  end

  def do_import(really_import=false)
    initialize_import
    begin
      transaction do
        get_ticket_orders
        # all is well!  Roll back the transaction and report results.
        raise TicketSalesImport::PreviewOnly unless really_import
        # finalize other changes
        @created_customers.each { |customer| customer.save! }
        @show.save!             # saves new showdates too
        @show.set_metadata_from_showdates! if @show_was_created
      end
    rescue TicketSalesImport::PreviewOnly
      ;
    rescue TicketSalesImport::ShowNotFound
      self.errors.add_to_base("Couldn't find production name in uploaded file")
    rescue Exception => e
      self.errors.add_to_base("Unexpected error: #{e.message} - #{e.backtrace}")
      RAILS_DEFAULT_LOGGER.info "Importing id #{self.id}: #{e.message}"
    end
    @vouchers
  end
  
  
  
  def import_customer(row,args)
    attribs = {}
    [:first_name, :last_name, :street, :city, :state, :zip, :day_phone, :email].each do |attr|
      attribs[attr] = row[args[attr]].to_s if args.has_key?(attr)
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

  def import_showdate(row,pos)
    event_date = Time.parse(row[pos].to_s)
    unless (self.show.showdates &&
        sd = self.show.showdates.detect { |sd| sd.thedate == event_date })
      sd = Showdate.placeholder(event_date)
      self.created_showdates << sd
      self.show.showdates << sd
    end
    sd
  end

  def find_or_create_show(name)
    if (s = Show.find_unique(name))
      self.show = s
      self.messages << "Show '#{name}' already exists (id=#{s.id})"
    else
      self.show = Show.create_placeholder!(name)
      @show_was_created = true
      self.messages << "Show '#{name}' will be created"
    end
  end
  
  
end
