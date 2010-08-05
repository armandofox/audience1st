class BrownPaperTicketsImport < TicketSalesImport
  require 'digest'
  
  protected
  
  def sanity_check
    @format_looks_ok &&
      (vouchers.length + existing_vouchers > 0) &&
      number_of_records > 0
  end

  def each_row
    delim = (public_filename =~ /\.csv$/i ?  "," : "\t")
    self.csv_rows(delim).each do |row|
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
        row[0].to_s =~ /^Will Call Tickets$/ || row[1].to_s =~ /^All Dates$/
      @uniquify_key = digest_from_string(row[0]) and next if row[0] =~ /^Sales list for/
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

  def ticket_order_from_row(row)
    bpt_order_id =  row[0].to_s
    # NEW-STYLE (6 digit) BPT order id's are not unique across shows, only within shows!!
    # so we prepend our own show ID here to make it unique.
    bpt_order_id = "#{@uniquify_key}#{bpt_order_id}" if bpt_order_id.length < 7
    self.existing_vouchers += 1 and return if already_entered?(bpt_order_id)
    
    customer = customer_from_row(row)
    showdate = showdate_from_row(row)
    vouchertype = vouchertype_from_row(row, showdate.thedate.year)
    order_date = Time.parse(row[1].to_s)
    order_notes = row[17].to_s

    voucher = Voucher.new_from_vouchertype(vouchertype, :showdate => showdate,
      :sold_on => order_date,
      :external_key => bpt_order_id,
      :comments => order_notes)
    customer.vouchers << voucher
    voucher
  end

  def vouchertype_from_row(row, year)
    name = row[18].to_s
    price = row[19].gsub(/[^0-9.]/,'').to_f
    unless (vt = Vouchertype.find_by_name_and_price_and_category(name, price, [:comp,:revenue]))
      vt = Vouchertype.create_external_voucher_for_season!(name, price, year.to_i) 
      @created_vouchertypes << vt
    end
    vt
  end
    
  def customer_from_row(row)
    return import_customer(row,
      :last_name => 6, :first_name => 7,
      :street => 8, :city => 9, :state => 10, :zip => 11,
      :day_phone => 13, :email => 14)
    #  not used: purchaser last/first name = 4,5 ; shipping country = 12
  end

  def showdate_from_row(row) ;  import_showdate(row[2]) ;  end
      
end
