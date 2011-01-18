class GoldstarCsvImport < TicketSalesImport

  # column indices
  LAST_NAME,FIRST_NAME,QTY,DATE,TIME,VOUCHERTYPE,EXTERNAL_KEY,NOTE = (1..8).to_a

  def sanity_check
    @showdate && @format_looks_ok
  end

  protected

  def each_row
    with_attachment_data do |fh|
      rows = CSV::Reader.create(fh.read)
      rows.each { |row| yield row.map(&:to_s) }
    end
  end

  def get_ticket_orders
    unless (@showdate = Showdate.find_by_id(self.showdate_id))
      errors.add_to_base "Invalid showdate ID #{showdate_id}"
      return []
    end
    messages << "Date: #{@showdate.printable_date}"
    @format_looks_ok = nil
    self.each_row do |row|
      @format_looks_ok = true and next if
        row[0,9] == ['Red Velvet', ' Last Name', ' First Name', ' Qty', ' Date', ' Time Note', ' Offer', ' Purchase #', ' Note']
      if content_row?(row)
        self.number_of_records += 1
        if (vouchers = ticket_order_from_row(row))
          @vouchers += vouchers
        end
        next
      end
    end
    unless @format_looks_ok
      errors.add_to_base "Expected header row not found"
    end
  end

  private

  def ticket_order_from_row(row)
    order_id = "GS#{row[EXTERNAL_KEY]}"
    raise "No order ID for row:\n#{row}" if order_id.blank?
    qty = row[QTY].to_i
    self.existing_vouchers += qty and return if already_entered?(order_id)
    customer = customer_from_row(row)
    vouchertype = vouchertype_from_row(row)
    order_date = Time.now
    order_notes = row[NOTE]
    vouchers = []
    1.upto(qty) do |i|
      vouchers << Voucher.new_from_vouchertype(vouchertype,
        :showdate => @showdate,
        :sold_on => order_date,
        :external_key => order_id,
        :comments => order_notes)
    end
    customer.vouchers += vouchers
    vouchers
  end

  def customer_from_row(row)
    import_customer_from_csv(row,
      :last_name => LAST_NAME,
      :first_name => FIRST_NAME)
  end

  def vouchertype_from_row(row)
    case row[VOUCHERTYPE]
    when /special/i
      unless (vt = Vouchertype.comp_vouchertypes(self.show.season).find { |v| v.price.zero? && v.name =~ /goldstar/i })
        raise TicketSalesImport::ImportError, "Goldstar Comp voucher type not defined"
      end
    when /general adm/i
      unless (vt = Vouchertype.revenue_vouchertypes(self.show.season).find { |v| !v.price.zero? && v.name =~ /goldstar/i })
        raise TicketSalesImport::ImportError, "Goldstar 1/2 Price voucher type not defined"
      end
    else
      raise TicketSalesImport::ImportError, "Unknown price point in import file: #{row[VOUCHERTYPE]}"
    end
    vt
  end
  
  def content_row?(row)
    row && !row[1].blank? && !row[2].blank?
  end

end
