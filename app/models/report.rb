class Report

  attr_accessor :customers, :output, :filename
  attr_reader :view_params
  attr_accessor :fields

  def initialize(fields=%w[email day_phone eve_phone])
    @fields = fields.map { |s| s.to_sym }
    @customers = []
    @errors = nil
    @output = ''
    @filename = self.class.to_s.downcase + Time.now.strftime("%Y_%m_%d")
    (@view_params ||= {})[:name] ||= self.class.to_s.humanize
  end

  def create_csv
    CSV::Writer.generate(@output='') do |csv|
      self.customers.each do |c|
        csv << [c.first_name.name_capitalize,
                c.last_name.name_capitalize,
                c.email,
                c.day_phone,
                c.eve_phone,
                c.street,c.city,c.state,c.zip,
                (c.created_on.to_formatted_s(:db) rescue nil)
               ]
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
