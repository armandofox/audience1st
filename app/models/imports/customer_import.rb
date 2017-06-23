class CustomerImport < Import

  MAX_PREVIEW_SIZE = 100 unless defined?(MAX_PREVIEW_SIZE)
  MAX_IMPORT = 100_000 unless defined?(MAX_IMPORT)

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
  
  def csv_rows
    with_attachment_data do |fh|
      CSV::Reader.create(fh.read, ',')
    end
  end
  
  protected

  def import(customer)
    return customer.save
  end

  def get_customers_to_import(max=MAX_IMPORT)
    customers = []
    self.number_of_records = 0
    begin
      self.csv_rows.each do |row|
        if (c = customer_from_csv_row(row))
          customers << c
          self.number_of_records += 1
        end
        break if number_of_records == max
      end
    rescue CSV::IllegalFormatError
      self.errors.add :base,"CSV file format is invalid starting at row #{number_of_records+1}.  If you created this CSV file on a Mac, be sure to select 'Windows Comma-Separated' as the file type to save."
    rescue Exception => e
      self.errors.add :base,e.message
      Rails.logger.info e.backtrace
    end
    return customers
  end
  
  def customer_from_csv_row(row)
    return nil if (!row || row.empty? || row[0].to_s.match(/first name/i))
    c = Customer.new(
      :first_name       => row[0],
      :last_name        => row[1],
      :email            => row[2],
      :street           => row[3],
      :city             => row[4],
      :state            => row[5],
      :zip              => row[6],
      :day_phone        => row[7],
      :eve_phone        => row[8],
      :blacklist        => !row[9].blank? ,
      :e_blacklist      => !row[10].blank? 
      )
    c.created_by_admin = true
    c
  end
  
end
