class CustomerImport < Import

  MAX_PREVIEW_SIZE = 10 unless defined?(MAX_PREVIEW_SIZE)
  MAX_IMPORT = 100_000 unless defined?(MAX_IMPORT)

  def preview
    return get_customers_to_import(MAX_PREVIEW_SIZE)
  end

  def num_records
    return get_customers_to_import(MAX_IMPORT, count_only = true)
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
      customer.save ? imports << customer : rejects << customer
    end
    return [imports,rejects]
  end
  
  private

  def get_customers_to_import(max=MAX_IMPORT,count_only = false)
    customers = []
    count = 0
    begin
      self.csv_rows.each do |row|
        if (c = customer_from_csv_row(row))
          customers << c unless count_only
          count += 1
        end
        break if count == max
      end
    rescue CSV::IllegalFormatError
      self.errors.add_to_base "CSV file format is invalid starting at row #{count+1}.  If you created this CSV file on a Mac, be sure to select 'Windows Comma-Separated' as the file type to save."
    rescue Exception => e
      self.errors.add_to_base e.message
    end
    return (count_only ? count : customers)
  end
  
  def customer_from_csv_row(row)
    return nil if (!row || row.empty? || row[0].to_s.match(/first name/i))
    c = Customer.new(
      :first_name       => row[0],
      :last_name        => row[1],
      :login            => row[2].blank? ? row[3] : row[2],
      :email            => row[3],
      :street           => row[4],
      :city             => row[5],
      :state            => row[6],
      :zip              => row[7],
      :day_phone        => row[8],
      :eve_phone        => row[9],
      :blacklist        => !row[10].blank? ,
      :e_blacklist      => !row[11].blank? ,
      :oldid            => row[12]
      )
  end
  
end
