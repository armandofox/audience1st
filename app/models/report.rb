class Report
  include FilenameUtils
  
  attr_accessor :output_options, :filename, :query
  attr_reader :view_params, :customers, :output
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
    @output_options_processed = {}
    @order = 'last_name,zip'
    @filename = filename_from_object(self)
    (@view_params ||= {})[:name] ||= self.class.to_s.humanize
  end

  def generate_and_postprocess(params)
    res = self.generate(params)
    @customers = self.postprocess(res)
  end
  
  def execute_query
    res = Customer.find_by_sql(query)
    logger.info "Report Query:\n  #{query.join("\n>> ")} \n==> #{@customers.length} results"
    @customers = postprocess(res)
  end

  def count ; make_query(count=true) ; end
  def query ; make_query(count=false) ; end

  def add_constraint(clause,*bind_vars)
    if clause.gsub!(/voucher\./, 'i.')
      add_join(:vouchers)
    elsif clause.gsub!(/vouchertype\./, 'vt.')
      add_join(:vouchertypes)
    elsif clause.gsub!(/donation\./, 'i.')
      add_join(:donations)
    else
      clause.gsub!(/customer\./, 'c.')
    end
    @wheres << clause
    @wheres.uniq!
    @bind_variables += bind_vars
  end

  def create_csv
    multicolumn = (@output_options['multi_column_address'].to_i > 0)
    header_row = (@output_options['header_row'].to_i > 0)
    CSV::Writer.generate(@output='') do |csv|
      begin
        if multicolumn
          csv << %w[first_name last_name email day_phone eve_phone street city state zip created_at] if header_row
          self.customers.each do |c|
            csv << [c.first_name.name_capitalize,
              c.last_name.name_capitalize,
              c.email,
              c.day_phone,
              c.eve_phone,
              c.street,c.city,c.state,c.zip,
              (c.created_at.to_formatted_s(:db) rescue nil)
            ]
          end
        else
          csv << %w[first_name last_name email day_phone eve_phone address created_at] if header_row
          self.customers.each do |c|
            addr = [c.street, c.city, c.state, c.zip].map { |str| str.to_s.gsub(/,/, ' ') }
            addr = addr[0,3].join(', ') << ' ' << addr[3]
            csv << [c.first_name.name_capitalize,
              c.last_name.name_capitalize,
              c.email,
              c.day_phone,
              c.eve_phone,
              addr,
              (c.created_at.to_formatted_s(:db) rescue nil)
            ]
          end
        end
      rescue Exception => e
        err = "Error in create_csv: #{e.message}"
        add_error(err)
        logger.error err
      end
    end
    @filename = filename_from_object(self)
  end

  def errors
    @errors.join("; ")
  end

  private

  def make_query(count=false)
    joins = @joins.join("\nLEFT OUTER JOIN ")
    # don't want to modify instance variables of these, lest this method
    # become non-idempotent
    wheres = @wheres.clone
    bind_variables = @bind_variables.clone
    @output_options.each_pair do |key, val|
      case key.to_sym
      when :exclude_blacklist
        wheres << "c.blacklist = #{val ? 0 : 1}"
        @output_options_processed[key] = true
      when :exclude_e_blacklist
        wheres << "c.e_blacklist = #{val ? 0 : 1}"
        @output_options_processed[key] = true
      when :require_valid_email
        (wheres << "c.email LIKE '%@%'") if val
        @output_options_processed[key] = true
      when :login_from
        if @output_options[:login_since]
          op = (@output_options[:login_since_test] =~ /not/ ?  '<=' : '>=')
          wheres << "c.last_login #{op} ?"
          bind_variables << Date::civil(val[:year].to_i, val[:month].to_i, val[:day].to_i)
        end
        @output_options_processed[key] = true
      when :require_valid_address
        wheres << "c.street != '' AND c.street IS NOT NULL" if !val.to_i.zero?
        @output_options_processed[key] = true
      when :filter_by_zip
        zips = @output_options[:zip_glob].split(/\s*,\s*/).map(&:to_i).reject { |zip| zip.zero? } # sanitize
        if !zips.empty?
          wheres << ('(c.zip = \'\' OR ' + Array.new(zips.length, "c.zip LIKE ?").join(' OR ') + ')')
          bind_variables += zips.map { |z| "#{z}%" }
        end
        @output_options_processed[key] = true
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
      @joins << 'items i on i.customer_id = c.id'
      @wheres << "i.type = 'Voucher'"
    elsif sym == :donations
      @joins << 'items i on i.customer_id = c.id'
      @wheres << "i.type = 'Donation'"
    elsif sym == :vouchertypes
      add_join(:vouchers)
      @joins << 'vouchertypes vt on i.vouchertype_id = vt.id'
    else
      raise 'Invalid call to add_join with #{sym}'
    end
    @joins.uniq!
  end

  def add_error(itm)
    (@errors ||= []) << itm.to_s
  end

  protected

  # there's a weirdness in Rails 2.3.x or else in Rack, where the
  # results of a multi-select box are returned in params[] as
  # ["3,4,5"] rather than ["3","4","5"].  strangely, the right thing
  # happens when submitted via an AJAX helper in Prototype, but the
  # wrong thing happens when submitted via form submit.  This method
  # handles either one until we figure out what the problem is.
  def self.list_of_ints_from_multiselect(ary)
    ary ||= []
    if (ary.length == 1 && ary[0] =~ /^[0-9,]+$/)
      ary = ary[0].split(',')
    end
    ary.map(&:to_i).reject(&:zero?)
  end

  def postprocess(arr)
    arr ||= []
    # if output options include stuff like duplicate elimination, do that here
    reject = []
    @output_options.each_pair do |key,val|
      next if val.nil? || @output_options_processed[key]
      case key.to_sym
      when :subscribers_only
        reject << '!c.subscriber?'
      when :exclude_blacklist
        reject << 'c.blacklist'
      when :exclude_e_blacklist
        reject << 'c.e_blacklist'
      when :require_valid_email
        reject << '!c.valid_email_address?'
      when :require_valid_address
        reject << '!c.valid_mailing_address?'
      when :filter_by_zip
        zips = @output_options[:zip_glob].split(/\s*,\s*/).join('|')
        reject << "(!c.zip.blank? && c.zip !~ /^(#{zips})/ )"
      when :login_from
        if @output_options[:login_since]
          date = "Date::civil(#{val[:year].to_i},#{val[:month].to_i},#{val[:day].to_i})"
          if @output_options[:login_since_test] =~ /not/
            reject << 'c.last_login >= #{date}'
          else
            reject << 'c.last_login <= #{date}'
          end
        end
      end
    end
    conds = reject.join(' || ')
    eval("arr.reject! { |c| #{conds} }")
    if @output_options[:remove_dups]
      # remove duplicate mailing addresses
      hshtemp = Hash.new
      arr.each_index do |i|
        canonical = arr[i].street.to_s.downcase.tr_s(' ', ' ')
        if hshtemp.has_key?(canonical)
          arr.delete_at(i)
        else
          hshtemp[canonical] = true
        end
      end
    end
    arr
  end
end
