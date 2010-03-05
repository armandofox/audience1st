class Report

  attr_accessor :customers, :output, :filename, :query
  attr_reader :view_params
  attr_accessor :fields, :log

  QUERY_TEMPLATE = %{
        SELECT DISTINCT c.*
        FROM %s
        WHERE %s
        ORDER BY %s
}

  def initialize(fields=%w[email day_phone eve_phone],output_options={})
    @fields = fields.map { |s| s.to_sym }
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
    parse_output_options
  end

  def query
    joins = @joins.join("\nLEFT OUTER JOIN ")
    wheres = @wheres.empty? ? '1' : @wheres.map { |s| "(#{s})" }.join(' AND ')
    query = sprintf(QUERY_TEMPLATE, joins, wheres, @order)
    @bind_variables.empty? ?  query : [query] + @bind_variables
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

  def make_query
    @wheres += parse_output_options
  end

  def parse_output_options
    @output_options.each_pair do |key, val|
      case key
      when :exclude_blacklist
        add_where 'c.blacklist = 0'
      when :exclude_e_blacklist
        add_where 'c.e_blacklist = 0'
      when :filter_by_zip
      end
    end
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
    @errors.to_s
  end

  protected
  def self.sanitize_sql(arg)
    ActiveRecord::Base.sanitize_sql(arg)
  end
end
