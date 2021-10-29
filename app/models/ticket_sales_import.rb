class TicketSalesImport < ActiveRecord::Base

  attr_accessor :warnings
  belongs_to :processed_by, :class_name => 'Customer'
  has_many :imported_orders, :dependent => :destroy

  class ImportError < StandardError ;  end

  # make sure all parser classes are loaded so we can validate against them
  Dir["#{Rails.root}/app/services/ticket_sales_import_parser/*.rb"].each { |f| load f }
  IMPORTERS =
    TicketSalesImportParser.constants.select { |c| const_get("TicketSalesImportParser::#{c}").is_a? Class }.
    map(&:to_s)

  validates_inclusion_of :vendor, :in => IMPORTERS
  validates_length_of :raw_data, :within => 1..65535
  validates_presence_of :processed_by
  validate :not_previously_imported?
  validate :valid_for_parsing?

  scope :sorted, -> { order('updated_at DESC') }
  scope :completed, -> { where(:completed => true) }
  scope :in_progress, -> { where(:completed => false) }
  scope :abandoned_since, ->(since) { where(:completed => false).where('updated_at < ?', since) }

  attr_reader :parser
  after_initialize :set_parser

  private

  def set_parser
    @warnings = ActiveModel::Errors.new(self)
    if IMPORTERS.include?(vendor)
      @parser = TicketSalesImportParser.const_get(vendor).send(:new, self)
    else
      errors.add(:parser, "is invalid")
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  public

  def not_previously_imported?
    # just in case, don't preload all imports!
    (TicketSalesImport.all - [self]).each do |i|
      if self.raw_data.strip == i.raw_data.strip
        msg = i.completed? ?
                I18n.translate('import.already_imported',
                               :date => i.updated_at.to_formatted_s(:foh),
                               :user => i.processed_by.full_name) :
                I18n.translate('import.already_in_progress',
                               :user => self.processed_by.full_name)
        return self.errors.add(:base, msg)
      end
    end
  end

  def valid_for_parsing?
    @parser.valid?
  end

  # Given a mapping of order_id => customer_id to use as order owner, 
  # finalize an import as long as all the orders are valid.  If any 
  # are not, add error messages to the import object and don't update it.
  def finalize(customer_for)
    begin
      ActiveRecord::Base.transaction do
        self.imported_orders.each do |order|
          order.processed_by = self.processed_by
          io = order.from_import
          sold_on = io.transaction_date
          # if a non-nil customer ID is specified, assign to that customer; else create new
          cid = customer_for[order.id.to_s].to_i
          if (cid != 0)
            order.finalize_with_existing_customer_id!(cid, self.processed_by, sold_on)
            self.existing_customers += 1
          else                  # create new customer
            customer = Customer.new(:first_name => io.first, :last_name => io.last,
                                    :email => io.email, :ticket_sales_import => self)
            order.finalize_with_new_customer!(customer, self.processed_by, sold_on)
            self.new_customers += 1
          end
          self.tickets_sold += order.ticket_count
        end
        self.completed = true
        self.save!
        true
      end                       # transaction block
    rescue Order::OrderFinalizeError => e
      raise e
    rescue ActiveRecord::RecordInvalid => e
      raise e
    rescue StandardError => e
      raise e
    end
  end

  # Check whether the import will exceed either the house capacity or a per-ticket-type capacity control
  def check_sales_limits
    showdates = Hash.new { 0 }
    num_of_type = Hash.new { 0 }
    imported_orders.reject(&:completed?).each do |i|
      i.vouchers.each do |voucher|
        # add tickets that will be imported for each showdate
        showdates[voucher.showdate] += 1
        num_of_type[ValidVoucher.find_by(:vouchertype => voucher.vouchertype, :showdate => voucher.showdate)] += 1
      end
    end
    showdates.each_pair do |showdate,num_to_import|
      current_sales = showdate.total_sales.size
      warning_params = { :num_to_import => num_to_import, :current_sales => current_sales,
        :performance_date => showdate.thedate.to_formatted_s(:showtime) }
      if current_sales + num_to_import > showdate.max_advance_sales
        @warnings.add(:base, I18n.translate('import.capacity_exceeded',
            warning_params.merge({:capacity_control => "performance's sales cap", :capacity => showdate.max_advance_sales})))
      end
      if current_sales + num_to_import > showdate.house_capacity
        @warnings.add(:base, I18n.translate('import.capacity_exceeded',
            warning_params.merge({:capacity_control => 'house capacity', :capacity => showdate.house_capacity})))
      end
    end
    num_of_type.each_pair do |vv, num_to_import|
      if vv.showdate.sales_by_type(vv.vouchertype_id) + num_to_import > vv.max_sales_for_type
        @warnings.add(:base, I18n.translate('import.max_sales_for_type_exceeded',
            :num_to_import => num_to_import, :vouchertype => vv.name, :max_sales_for_type => vv.max_sales_for_type,
            :performance_date => vv.thedate.to_formatted_s(:showtime)))
      end
    end
  end
end
