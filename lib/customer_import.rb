class CustomerImport

  attr_accessor :name, :filename, :content_type, :size, :number_of_records, :public_filename, :errors

  MAX_PREVIEW_SIZE = 100 unless defined?(MAX_PREVIEW_SIZE)
  MAX_IMPORT = 100_000 unless defined?(MAX_IMPORT)

  def initialize
    @errors = ActiveModel::Errors.new(self)
  end

  def preview
    return get_customers_to_import(MAX_PREVIEW_SIZE)
  end

  def valid_records
    return get_customers_to_import.collect { |c| c.valid? }
  end

  def invalid_records
    return get_customers_to_import.reject { |c| c.valid? }
  end

  def import!
    customers = get_customers_to_import
    imports = []
    rejects = []
    customers.each do |customer|
      import(customer) ? imports << customer : rejects << customer
    end
    self.number_of_records = imports.length
    return [imports,rejects]
  end
  
  protected

  def import(customer)
    return customer.save
  end

  def get_customers_to_import(max=MAX_IMPORT)
    customers = []
    self.number_of_records = 0
    begin
      CSV.foreach(self.attachment_filename, :headers => true, :skip_blanks => true, :converters => []) do |row|
        if (c = customer_from_csv_row(row))
          customers << c
          self.number_of_records += 1
        end
        break if number_of_records == max
      end
    rescue CSV::MalformedCSVError
      self.errors.add :base,"CSV file format is invalid starting at row #{number_of_records+1}.  If you created this CSV file on a Mac, be sure to select 'Windows Comma-Separated' as the file type to save."
    rescue StandardError => e
      self.errors.add :base,e.message
      Rails.logger.info e.backtrace
    end
    return customers
  end
  
  def customer_from_csv_row(row)
    c = Customer.new(
      :first_name       => row["First name"],
      :last_name        => row["Last name"],
      :email            => row["Email"],
      :street           => row["Street"],
      :city             => row["City"],
      :state            => row["State"],
      :zip              => row["Zip"],
      :day_phone        => row["Day/primary phone"],
      :eve_phone        => row["Eve/secondary phone"],
      :blacklist        => ! row["Don't mail"].blank?,
      :e_blacklist      => ! row["Don't email"].blank? 
      )
    c.created_by_admin = true
    c
  end
  
end
