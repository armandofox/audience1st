class Report

  attr_accessor :output_options, :filename, :query
  attr_reader :view_params, :customers
  attr_accessor :fields, :log

  cattr_accessor :logger

  @@logger = RAILS_DEFAULT_LOGGER

  QUERY_TEMPLATE = %{
        SELECT DISTINCT %s
        FROM %s
        WHERE %s
        ORDER BY %s
}

  public
  
  def initialize(output_options={})
    @fields = %w[email day_phone eve_phone].map { |s| s.to_sym }
    @customers = []
    @errors = nil
    @output = ''
    @joins = ['customers c']
    @wheres = []
    @bind_variables = []
    @output_options = output_options
    @order = 'last_name,zip'
    @filename = self.class.to_s.downcase + Time.now.strftime("%Y_%m_%d")
    (@view_params ||= {})[:name] ||= self.class.to_s.humanize
  end

  def execute_query
    @customers = Customer.find_by_sql(query)
    logger.info "Report Query:\n  #{query} \n   => #{@customers.length} results"
    @customers
  end

  def count ; make_query(count=true) ; end
  def query ; make_query(count=false) ; end

  def add_constraint(clause,*bind_vars)
    if clause.gsub!(/voucher\./, 'v.')
      add_join(:vouchers)
    elsif clause.gsub!(/vouchertype\./, 'vt.')
      add_join(:vouchertypes)
    elsif clause.gsub!(/donation\./, 'd.')
      add_join(:donations)
    else
      clause.gsub!(/customer\./, 'c.')
    end
    @wheres << clause
    @wheres.uniq!
    @bind_variables += bind_vars
  end

  def create_csv
    CSV::Writer.generate(@output='') do |csv|
      self.customers.each do |c|
        begin
          csv << [c.first_name.name_capitalize,
            c.last_name.name_capitalize,
            c.email,
            c.day_phone,
            c.eve_phone,
            c.street,c.city,c.state,c.zip,
            (c.created_on.to_formatted_s(:db) rescue nil)
          ]
        rescue Exception => e
          logger.error "Error in create_csv: #{e.message}"
        end
      end
    end
    @filename = self.class.to_s.downcase + Time.now.strftime("%Y_%m_%d")
  end

  def errors
    @errors.join("; ")
  end

  private

  def make_query(count=false)
    joins = @joins.join("\nLEFT OUTER JOIN ")
    # don't want to modify instance variables of these, lest this method
    # become non-idempotent
    wheres = @wheres
    bind_variables = @bind_variables
    @output_options.each_pair do |key, val|
      case key.to_sym
      when :exclude_blacklist
        wheres << "c.blacklist = #{val ? 0 : 1}"
      when :exclude_e_blacklist
        wheres << "c.e_blacklist = #{val ? 0 : 1}"
      when :filter_by_zip
        zips = @output_options[:zip_glob].split(/\s*,\s*/).map(&:to_i).reject { |zip| zip.zero? } # sanitize
        if !zips.empty?
          wheres << ('(' + Array.new(zips.length, "c.zip LIKE ?").join(' OR ') + ')')
          bind_variables += zips.map { |z| "#{z}%" }
        end
      end
    end
    wheres.uniq!
    wheres = wheres.empty? ? '1' : wheres.map { |s| "(#{s})" }.join(' AND ')
    query = sprintf(QUERY_TEMPLATE, (count ? 'COUNT(*)' : 'c.*'),
      joins, wheres, @order)
    [query] + bind_variables
  end
  
  def add_join(sym)
    if sym == :vouchers
      @joins << 'vouchers v on v.customer_id = c.id'
    elsif sym == :donations
      @joins << 'donations d on d.customer_id = c.id'
    elsif sym == :vouchertypes
      add_join(:vouchers)
      @joins << 'vouchertypes vt on v.vouchertype_id = vt.id'
    else
      raise 'Invalid call to add_join with #{sym}'
    end
    @joins.uniq!
  end

  def add_error(itm)
    (@errors ||= []) << itm.to_s
  end
end
