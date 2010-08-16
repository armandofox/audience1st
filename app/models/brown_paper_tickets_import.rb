class BrownPaperTicketsImport < TicketSalesImport
  require 'digest'
  
  protected

  # column indices - BPT keeps changing these
  ORDER_DATE = self.col_index :c
  ORDER_NOTES = self.col_index :s
  VOUCHERTYPE_NAME = self.col_index :t
  PRICE = self.col_index :u

  SHOWDATE = self.col_index :d

  LAST_NAME = self.col_index :h
  FIRST_NAME = self.col_index :i
  STREET = self.col_index :j
  CITY = self.col_index :k
  STATE = self.col_index :l
  ZIP = self.col_index :m
  PHONE = self.col_index :o
  EMAIL = self.col_index :p
  
  def sanity_check
    @format_looks_ok &&
      (vouchers.length + existing_vouchers > 0) &&
      number_of_records > 0
  end

  def each_row
    self.csv_rows("\t").each do |row|
      yield row.map(&:to_s)
    end
  end

  private

  def digest_from_string(str) ;  Digest::SHA1.hexdigest(str)[-3,3].hex ; end

  def get_ticket_orders
    # production name is in cell A2; be sure "All Dates" is B2
    @format_looks_ok = nil
    self.each_row do |row|
      @format_looks_ok = true and next if
        row[0] =~ /^Will Call Tickets$/ || row[1] =~ /^All Dates$/
      if (content_row?(row))
        self.number_of_records += 1 
        if (voucher = ticket_order_from_row(row))
          @vouchers << voucher
        end
        next
      end
    end
  end

  def content_row?(row) ; row[0].to_s =~ /^\s*[0-9]{6,}$/ ; end

  def get_unique_order_id_from_row(row)
    (row[0].to_i + row[1].to_i).to_s
  end

  def ticket_order_from_row(row)
    bpt_order_id = get_unique_order_id_from_row(row)
    self.existing_vouchers += 1 and return if already_entered?(bpt_order_id)
    
    customer = customer_from_row(row)
    showdate = showdate_from_row(row)
    vouchertype = vouchertype_from_row(row, showdate.thedate.year)
    order_date = Time.parse(row[ORDER_DATE])
    order_notes = row[ORDER_NOTES].to_s

    voucher = Voucher.new_from_vouchertype(vouchertype, :showdate => showdate,
      :sold_on => order_date,
      :external_key => bpt_order_id,
      :comments => order_notes)
    customer.vouchers << voucher
    voucher
  end

  def vouchertype_from_row(row, year)
    name = row[VOUCHERTYPE_NAME].to_s[0,Vouchertype::NAME_LIMIT]
    price = row[PRICE].gsub(/[^0-9.]/,'').to_f
    unless (vt = Vouchertype.find_by_name_and_price_and_category(name, price, [:comp,:revenue]))
      vt = Vouchertype.create_external_voucher_for_season!(name, price, year.to_i) 
      @created_vouchertypes << vt
    end
    vt
  end
    
  def customer_from_row(row)
    return import_customer(row,
      :last_name => LAST_NAME, :first_name => FIRST_NAME,
      :street => STREET, :city => CITY, :state => STATE, :zip => ZIP,
      :day_phone => PHONE, :email => EMAIL,
      :last_login => ORDER_DATE, :updated_at => ORDER_DATE)
    #  not used: purchaser last/first name = 4,5 ; shipping country = 12
  end

  def showdate_from_row(row) ;  import_showdate(row[SHOWDATE]) ;  end
      
end
