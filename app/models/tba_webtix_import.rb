class TBAWebtixImport < Import
  require 'dbf'

  private

  def sanity_check
    nil
  end
  
  # iterator that yields each row of a DBF as an array of strings, like csv_rows
  def each_row
    DBF::Table.new(self.public_filename).each do |row|
      next if row.nil?
      yield row.to_a
    end
  end

  def get_ticket_orders
    check_columns = nil
    self.each_row do |row|
      # first row should contain all headers
    end
  end

  def content_row?(row) ; row[0] =~ /^[0-9]{6,}$/ ; end

  def customer_from_row(row)
    # customer info:
    import_customer(row,
      :last_name => 75, :first_name => 74,
      :street => 77, :city => 78, :state => 79, :zip => 80,
      :day_phone => 86, :email => 87)
  end


end
