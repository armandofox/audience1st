class CustomerImport < Import

  Import.add_import_type "Customer/mailing list", 'CustomerImport'
  MAX_PREVIEW_SIZE = 10 unless defined?(MAX_PREVIEW_SIZE)

  def preview
    @customers = []
    count = 0
    self.csv_rows.each do |row|
      if (c = customer_from_csv_row(row))
        @customers << c
        count += 1
      end
      break if count == MAX_PREVIEW_SIZE
    end
    @customers
  end

  private

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
