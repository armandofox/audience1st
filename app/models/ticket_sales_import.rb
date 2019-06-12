class TicketSalesImport < ActiveRecord::Base

  attr_accessible :vendor, :raw_data, :processed_by, :existing_customers, :new_customers, :tickets_sold
  attr_reader :importable_orders
  attr_accessor :warnings
  belongs_to :processed_by, :class_name => 'Customer'

  class ImportError < StandardError ;  end

  # make sure all parser classes are loaded so we can validate against them
  Dir["#{Rails.root}/app/services/ticket_sales_import_parser/*.rb"].each { |f| load f }
  IMPORTERS =
    TicketSalesImportParser.constants.select { |c| const_get("TicketSalesImportParser::#{c}").is_a? Class }.
    map(&:to_s)

  validates_inclusion_of :vendor, :in => IMPORTERS
  validates_length_of :raw_data, :within => 1..65535
  validate :not_previously_imported?
  validate :valid_for_parsing?
  
  scope :sorted, -> { order('updated_at DESC') }

  attr_reader :parser
  after_initialize :set_parser

  private

  def set_parser
    @importable_orders = []
    @warnings = []
    if IMPORTERS.include?(vendor)
      @parser = TicketSalesImportParser.const_get(vendor).send(:new, self)
    else
      errors.add(:parser, "is invalid")
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  def not_previously_imported?
    # just in case, don't preload all imports!
    TicketSalesImport.all.each do |i|
      if i.completed? && self.raw_data.strip == i.raw_data.strip
        self.errors.add(:base, I18n.translate('import.already_imported',
            :date => i.updated_at.to_formatted_s(:month_day_year)))
        return nil
      end
    end
    true
  end

  def valid_for_parsing?
    @parser.valid?
  end

  public

  def parse
    @importable_orders = @parser.parse
    @importable_orders.each do |imp|
      imp.order.save! unless imp.already_imported?
    end
  end

  def completed?
    ! (created_at == updated_at)
  end
  
  def finalize!
    @importable_orders.each do |imp|
      imp.finalize!
    end
  end

end
