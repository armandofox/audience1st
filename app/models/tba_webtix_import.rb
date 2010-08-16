class TBAWebtixImport < TicketSalesImport
  require 'dbf' # for parsing DBase II exported files from Webtix

  TBA_VOUCHERTYPE_NAME = "TBA Half Price"

  protected

  def sanity_check
    (vouchers.length + existing_vouchers > 0) &&
      number_of_records > 0
  end
  
  # iterator that yields each row of a DBF as an array of strings, like csv_rows
  def each_row
    @table.each do |row|
      r = row.to_a
      yield r unless r.empty?
    end
  end

  private

  def get_ticket_orders
    verify_table_format
    self.each_row do |row|
      next unless content_row?(row)
      if (vouchers = ticket_order_from_row(row))
        self.number_of_records += 1
        @vouchers += vouchers
      end
    end
  end

  def verify_table_format
    @table = DBF::Table.new(self.public_filename)
    raise(TicketSalesImport::ImportError, "Unable to convert exported table") unless @table
    raise(TicketSalesImport::ImportError, "Wrong number of columns in exported table (expected 96, got #{@table.columns.length})") unless
      @table.columns.length == 96
    raise(TicketSalesImport::ImportError, "Unexpected column headers") unless
      @table.columns[0].name == 'ORDERNUM' && @table.columns[95].name == 'COUNTRY2'
    true
  end

  def content_row?(row) ; row[0].to_s.strip =~ /^[0-9]{6,}$/ ; end

  def ticket_order_from_row(row)
    # since our order ID's must be unique, we use the order ID plus
    # 2 digits, to capture up to 99 tickets associated with a single
    # TBA order id.  eg 123456 in TBA becomes 12345600, 12345601, etc. in A1.
    order_id = "#{row[0]}00"
    total_tix = row[col_index(:f)].to_i
    self.existing_vouchers += total_tix and return if already_entered?(order_id)
    customer = customer_from_row(row)
    showdate = showdate_from_row(row)
    order_date = Time.parse "#{row[col_index :j]} #{row[col_index :k]}"
    comments = row[col_index(:ce)]
    total_paid = row[col_index(:g)].to_f
    service_charge = row[col_index(:n)].to_f
    price_each = (total_paid - service_charge) / total_tix
    vouchertype = get_or_create_vouchertype(price_each, showdate.thedate.year)
    vouchers = Array.new(total_tix) do |ticket_number|
      Voucher.new_from_vouchertype(vouchertype,
        :showdate => showdate,
        :sold_on => order_date,
        :comments => comments,
        :external_key => order_id + sprintf("%02d", ticket_number))
    end
    customer.vouchers += vouchers
    vouchers
  end
  
  def customer_from_row(row)
    # customer info:
    import_customer(row,
      :last_name => col_index(:bx),
      :first_name => col_index(:bw),
      :street => col_index(:bz),
      :city => col_index(:ca),
      :state => col_index(:cb),
      :zip => col_index(:cc),
      :day_phone => col_index(:ci),
      :email => col_index(:cj),
      :last_login => col_index(:j),
      :updated_at => col_index(:j)
      )
  end

  def showdate_from_row(row) ;  import_showdate "#{row[2]} #{row[3]}" ; end

  def get_or_create_vouchertype(price,valid_year)
    if (v = Vouchertype.find(:first,
          :conditions => "price = #{price} AND name LIKE '#{TBA_VOUCHERTYPE_NAME}%'"))
      @vouchertype = v
    else
      count_existing_tba_vouchertypes =
        Vouchertype.count(:conditions => "name LIKE '#{TBA_VOUCHERTYPE_NAME}%'")
      new_vouchertype_name =
        "#{TBA_VOUCHERTYPE_NAME} #{count_existing_tba_vouchertypes+1}"
      @vouchertype =
        Vouchertype.create_external_voucher_for_season!(new_vouchertype_name, price, valid_year)
      @created_vouchertypes << @vouchertype
    end
    @vouchertype
  end

end

