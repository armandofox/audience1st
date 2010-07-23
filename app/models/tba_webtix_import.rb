class TBAWebtixImport < Import
  require 'dbf'

  private

  # iterator that yields each row of a DBF as an array of strings, like csv_rows
  def dbf_rows
    DBF::Table.new(self.public_filename).each do |row|
      next if row.nil?
      yield row.to_a
    end
  end

  def get_ticket_orders
    check_columns = nil
    self.dbf_rows.each do |row|
      # first row should contain all headers
    end
  end

  def content_row?(row) ; row[0].to_s =~ /^[0-9]{6,}$/ ; end

  def customer_from_row(row)
    # customer info:
    import_customer(row,
      :last_name => 75, :first_name => 74,
      :street => 77, :city => 78, :state => 79, :zip => 80,
      :day_phone => 86, :email => 87)
  end


end
