class Report
  include FilenameUtils
  require 'csv'

  attr_accessor :output_options, :filename, :query
  attr_reader :relation, :view_params, :customers, :output
  attr_accessor :fields, :log

  if self.subclasses.empty?
    Dir["#{Rails.root}/app/models/reports/*.rb"].each do |file|
      require_dependency file
    end
  end

  public
  
  def initialize(output_options={})
    @customers = []
    @errors = nil
    @output = ''
    @output_options = output_options
    @filename = filename_from_object(self)
    @relation = nil
    (@view_params ||= {})[:name] ||= self.class.to_s.humanize
  end

  def generate_and_postprocess(params)
    @relation = self.generate(params)
    @customers = self.postprocess
  end
  
  def create_csv
    multicolumn = (@output_options['multi_column_address'].to_i > 0)
    header_row = (@output_options['header_row'].to_i > 0)
    @output = CSV.generate do |csv|
      begin
        if multicolumn
          csv << %w[first_name last_name email day_phone eve_phone street city state zip labels created_at] if header_row
          self.customers.each do |c|
            csv << [c.first_name.name_capitalize,
              c.last_name.name_capitalize,
              c.email,
              c.day_phone,
              c.eve_phone,
              c.street,c.city,c.state,c.zip,
              c.labels.map(&:name).join(':'),
              (c.created_at.to_formatted_s(:db) rescue nil)
            ]
          end
        else
          csv << %w[first_name last_name email day_phone eve_phone address labels created_at] if header_row
          self.customers.each do |c|
            addr = [c.street, c.city, c.state, c.zip].map { |str| str.to_s.gsub(/,/, ' ') }
            addr = addr[0,3].join(', ') << ' ' << addr[3]
            csv << [c.first_name.name_capitalize,
              c.last_name.name_capitalize,
              c.email,
              c.day_phone,
              c.eve_phone,
              addr,
              c.labels.map(&:name).join(':'),
              (c.created_at.to_formatted_s(:db) rescue nil)
            ]
          end
        end
      rescue RuntimeError => e
        err = "Error in create_csv: #{e.message}"
        add_error(err)
        Rails.logger.error err
      end
    end
    @filename = filename_from_object(self)
  end

  def errors
    @errors.join("; ")
  end

  private

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

  def postprocess
    # things we can do on the relation
    # we always seem to need Labels to include as part of result
    @relation = @relation.includes(:labels)
    @output_options.each_pair do |option,value|
      case option
      when :exclude_blacklist then @relation = @relation.where(:blacklist => false)
      when :exclude_e_blacklist then @relation = @relation.where(:e_blacklist => false)
      when :require_valid_email then @relation = @relation.where.not(:email => [nil,''])
      when :require_valid_address then @relation = @relation.where.
          not(:street => [nil,'']).
          not(:city => [nil,'']).not(:state => [nil,''])
      when :login_from
        if (fields = @output_options[:login_since])
          date = Date::civil(fields[:year].to_i,fields[:month].to_i,fields[:day].to_i)
          if @output_options[:login_since_test] =~ /not/
            @relation = @relation.where('customers.last_login >= ?', date)
          else
            @relation = @relation.where('customers.last_login <= ?', date)
          end
        end
      end
    end

    # The rest of the checks must be done on the complete collection.
    arr = @relation.to_a
    # This can eventually become a simple column check
    case @output_options.delete(:subscribers)
    when 'Subscribers only' then    arr.select!(&:subscriber?)
    when 'Nonsubscribers only' then arr.reject!(&:subscriber?)
    end

    # if output options include stuff like duplicate elimination, do that here
    if @output_options[:filter_by_zip]
      zips = @output_options[:zip_glob].split(/\s*,\s*/).join('|')
      arr.reject! { |c| !c.zip.blank? && c.zip !~ /^(#{zips})/ }
    end

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
