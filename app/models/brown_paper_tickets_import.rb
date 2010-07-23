class BrownPaperTicketsImport < TicketSalesImport

  private

  def get_ticket_orders
    # production name is in cell A2; be sure "All Dates" is B2
    self.csv_rows.each do |row|
      find_or_create_show(row[0].to_s) and next if row[1].to_s == 'All Dates'
      if (content_row?(row))
        @num_records += 1 
        if (voucher = ticket_order_from_row(row))
          @vouchers << voucher
        end
        next
      end
    end
  end

  def content_row?(row) ; row[0].to_s =~ /^\s*[0-9]{7,}$/ ; end

  def ticket_order_from_row(row)
    raise(TicketSalesImport::ShowNotFound, "Invalid spreadsheet: no show name found, or spreadsheet may be correupted") unless @show

    bpt_order_id = row[0].to_s
    @existing_vouchers += 1 and return nil if Voucher.find_by_external_key(bpt_order_id)
    
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
    price = row[19].to_f
    unless (vt = Vouchertype.find_by_name_and_price_and_category(name, price, [:comp,:revenue]))
      vt = Vouchertype.create_external_voucher_for_season!("#{name} (BPT)", price, year.to_i) 
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

  def showdate_from_row(row) ;  import_showdate(row, 2) ;  end
      
end
