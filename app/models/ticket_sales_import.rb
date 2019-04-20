class TicketSalesImport < ActiveRecord::Base

  attr_accessible :vendor, :raw_data

  # make sure all parser classes are loaded so we can validate against them
  Dir["#{Rails.root}/app/services/ticket_sales_import_parser/*.rb"].each { |f| load f }
  IMPORTERS =
    TicketSalesImportParser.constants.select { |c| const_get("TicketSalesImportParser::#{c}").is_a? Class }.
    map(&:to_s)

  validates_inclusion_of :vendor, :in => IMPORTERS
  validates_length_of :raw_data, :within => 1..65535
  validate :valid_for_parsing?

  scope :sorted, -> { order('completed DESC, updated_at DESC') }

  attr_reader :parser
  after_initialize :set_parser

  private

  def set_parser
    if IMPORTERS.include?(vendor)
      @parser = TicketSalesImportParser.const_get(vendor).send(:new, self)
    else
      errors.add(:parser, "is invalid")
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  def valid_for_parsing?
    @parser.valid?
  end
  


end
