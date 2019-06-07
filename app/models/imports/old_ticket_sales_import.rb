class OldTicketSalesImport < Import

  belongs_to :show
  validates_associated :show
  validate :show_exists?, :unless => :show_is_part_of_import?

  class TicketSalesImport::DateTimeNotFound < Exception ; end
  class TicketSalesImport::ShowNotFound < Exception ; end
  class TicketSalesImport::CustomerNameNotFound < Exception ; end
  class TicketSalesImport::MultipleShowMatches < Exception ; end
  class TicketSalesImport::PreviewOnly  < Exception ; end
  class TicketSalesImport::ImportError < Exception ; end
  class TicketSalesImport::BadOrderFormat < Exception ; end

  attr_accessor :vouchers, :existing_vouchers
  attr_accessor :created_customers, :matched_customers
  attr_accessor :created_showdates, :created_vouchertypes

  public

  # Override in subclasses whose import files are self-contained to include show/date info
  def show_is_part_of_import? ; nil ; end

  def show_exists?
    errors.add(:base,'You must specify an existing show.')  and return nil unless  self.show_id && Show.find_by_id(show_id)
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

  def import!
    result = do_import(true)
    self.number_of_records = result.length
    [result, []]
  end

  def valid_records ; number_of_records ; end
  def invalid_records ; 0 ; end

  after_initialize :init_my_attributes

  protected

  def sanity_check ; nil ; end

  def self.col_index(letters)
    letters = letters.to_s.downcase.split('')
    letters.length == 1 ?
    letters[0].ord - 97 :
      26 * (letters[0].ord - 96) + (letters[1].ord - 97)
  end
  def col_index(letters) ; TicketSalesImport.col_index(letters) ; end
  
  def init_my_attributes          # called after AR::Base makes a new obj
    self.messages ||= []
    self.messages << "Show: #{show.name}" if show
    self.vouchers = []
    self.created_customers = []
    self.matched_customers = []
    self.created_showdates = []
    self.created_vouchertypes = []
    self.existing_vouchers = 0
  end

  def get_ticket_orders ; raise RuntimeError, "Must override this method" ; end

  def do_import(really_import=false)
    unless (show_is_part_of_import? || show_exists?)
      self.errors.add :base,"No show name given, or show does not exist"
      return []
    end
    begin
      transaction do
        get_ticket_orders
        show.adjust_metadata_from_showdates
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
      self.errors.add(:base,"Format error in .CSV file.  If you created this file on a Mac, be sure it's saved as Windows CSV.")
    rescue TicketSalesImport::PreviewOnly
      ;
    rescue TicketSalesImport::BadOrderFormat => e
      self.errors.add(:base,"Malformed individual order: #{e.message}")
    rescue TicketSalesImport::CustomerNameNotFound => e
      self.errors.add(:base,"Customer name not found for #{e.message}")
    rescue TicketSalesImport::ShowNotFound => e
      self.errors.add(:base,"Couldn't find production name/date matching '#{e.message}'")
    rescue TicketSalesImport::DateTimeNotFound => e
      self.errors.add(:base,"Couldn't find valid date and time in import document (#{e.message})")
    rescue TicketSalesImport::MultipleShowMatches => e
      self.errors.add(:base,"Multiple showdates match import file: #{e.message}")
    rescue TicketSalesImport::ImportError => e
      self.errors.add(:base,e.message)
    rescue Exception => e
      self.errors.add(:base,"Unexpected error: #{e.message}")
      Rails.logger.info "Importing id #{self.id || '<none>'} at record #{self.number_of_records}: #{e.message}\n#{e.backtrace}"
    end
    @vouchers
  end
  
  def import_customer_from_csv(row,args)
    attribs = {}
    [:first_name, :last_name, :street, :city, :state, :zip, :day_phone, :email, :last_login, :updated_at].each do |attr|
      # special case: "N/A" is same as blank
      attribs[attr] = row[args[attr]] if (args.has_key?(attr)  && row[args[attr]] != 'N/A')
    end
    import_customer(attribs)
  end

  def import_customer(attribs)
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
    raise TicketSalesImport::ImportError, "Time parsing needs to be updated"
    event_date = Time.zone.parse(time_as_str)
    unless (self.show.showdates &&
        sd = self.show.showdates.detect { |sd| sd.thedate == event_date })
      sd = Showdate.placeholder(event_date)
      self.created_showdates << sd
      self.show.showdates << sd
    end
    sd
  end

  def already_entered?(order_id)
    raise "External key is null - cannot check for duplicates" if order_id.blank?
    return nil unless (v = Voucher.find_by_external_key(order_id))
    # this voucher's already been entered.  make sure show name matches!!
    raise(TicketSalesImport::ImportError,
      "Existing order #{order_id} was already entered, but for a different show (#{v.show.name}, show ID #{v.show.id})") if
      v.show != self.show
    true
  end

  def get_or_create_vouchertype(price,name,valid_year=Time.current.year)
    name_match = "%#{name}%"
    if (v = Vouchertype.where("price = #{price} AND name LIKE ?", name_match).first)
      @vouchertype = v
    else
      count_existing_vouchertypes =
        Vouchertype.where('name LIKE ?', name_match).count
      new_vouchertype_name =
        "#{name} #{count_existing_vouchertypes+1}"
      @vouchertype =
        Vouchertype.create_external_voucher_for_season!(new_vouchertype_name, price, valid_year)
      @created_vouchertypes << @vouchertype
    end
    @vouchertype
  end


end
