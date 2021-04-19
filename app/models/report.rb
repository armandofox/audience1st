class Report
  require 'csv'

  attr_accessor :output_options, :filename, :query
  attr_reader :relation, :view_params, :customers, :output, :errors
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
    @filename = "report-#{Time.current.to_formatted_s(:filename)}.csv"
    @relation = nil   # generic empty chainable relation
    (@view_params ||= {})[:name] ||= self.class.to_s.humanize
  end

  def generate_and_postprocess(params)
    self.generate(params)
    @customers = if @relation then self.postprocess else Customer.none end
  end
  
  def create_csv
    # if multi-tenancy in use, we MUST capture the tenant name so we can EXPLICITLY switch
    # to that tenant in the block passed to Enumerator.new.  This is because that block will
    # be executed (ie the enumerator will be unrolled) AFTER we have left Rails and the
    # response is being played back by Rack, so the block will execute OUTSIDE the scope
    # of the "current tenant".
    if Figaro.env.tenant_names.blank?
      # no multitenant
      @output = Enumerator.new do |csv|
        add_header_row(csv)
        add_data_rows(csv)
      end
    else
      current_tenant = Apartment::Tenant.current      # capture for use in closure
      @output = Enumerator.new do |csv|
        add_header_row(csv)
        Apartment::Tenant.switch(current_tenant) do
          add_data_rows(csv)
        end
      end
    end
  end

  def add_error(itm)
    (@errors ||= '') << itm << '  '
    itm.to_s
  end

  private

  def add_header_row(csv)
    @headers = %w[first_name last_name email day_phone eve_phone street city state zip no_mail no_email labels created_at role_name] 
    csv << CSV::Row.new(@headers, @headers, header_row = true).to_s
  end

  def add_data_rows(csv)
    # grab the IDs of the whole set, then find in batches to avoid instantiating lots of objects
    order = self.output_options[:sort_by_zip] == '1' ?
              "customers.zip, customers.last_name" :
              "customers.last_name, customers.zip"
    ordered_ids = self.customers.unscoped.order(order).pluck(:id).uniq
    batch_size = 500
    ordered_ids.in_groups_of(batch_size, false) do |ids|
      self.customers.where(:id => ids).order(order).each do |c|
        csv << CSV::Row.new(
          @headers,
          [ c.first_name.name_capitalize,
            c.last_name.name_capitalize,
            c.email,
            c.day_phone,
            c.eve_phone,
            c.street,c.city,c.state,c.zip,
            ("true" if c.blacklist?),
            ("true" if c.e_blacklist?),
            c.labels.map(&:name).join(':'),
            (c.created_at.to_formatted_s(:db) rescue nil),
            c.role_name
          ],
          header_row = false
        ).to_s
      end
    end
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
      case option.to_sym
      when :exclude_blacklist then @relation = @relation.where('customers.blacklist' => false)
      when :exclude_e_blacklist then @relation = @relation.where('customers.e_blacklist' => false)
      when :require_valid_email then @relation = @relation.where.not('customers.email' => [nil,''])
      when :require_valid_address then @relation = @relation.where.
          not('customers.street' => [nil,''], 'customers.city' => [nil,''], 'customers.state' => [nil,''])
      when :include
        if value =~ /non-subscribers/i
          @relation = @relation.nonsubscriber_during(Time.this_season)
        elsif value =~ / subscribers/i
          @relation = @relation.subscriber_during(Time.this_season)
        end
        # otherwise include everyone
      when :login_from
        if @output_options[:login_since]
          fields = @output_options[:login_from]
          date = Date::civil(fields[:year].to_i,fields[:month].to_i,fields[:day].to_i)
          if @output_options[:login_since_test] =~ /not/
            @relation = @relation.where('customers.last_login >= ?', date)
          else
            @relation = @relation.where('customers.last_login <= ?', date)
          end
        end
      when :filter_by_zip
        next if @output_options[:zip_glob].blank?
        # construct a LIKE clause that matches zips starting with anything in glob
        zips = @output_options[:zip_glob].split(/\s*,\s*/).map { |z| "#{z}%" }
        constraints = Array.new(zips.size) { '(customers.zip LIKE ?)' }.join(' OR ')
        @relation = @relation.where(constraints, *zips)
      end
    end
    @relation
  end

end
