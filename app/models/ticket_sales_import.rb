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
