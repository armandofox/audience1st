class BrownPaperTicketsImport < Import

  attr_accessor :show, :created_customers, :created_showdates, :created_vouchertypes

  class BrownPaperTicketsImport::ShowNotFound < Exception ; end
  class BrownPaperTicketsImport::PreviewOnly  < Exception ; end
  
  def initialize_import
    @created_customers = 0
    @matched_customers = 0
    @created_showdates = 0
    @created_vouchertypes = 0
    @show = nil
    @vouchers = []
    @existing_vouchers = 0
    @num_records = nil
  end

  def preview
    initialize_import
    self.pretend = true
    begin
      transaction do
        get_ticket_orders
        # all is well!
        raise BrownPaperTicketsImport::PreviewOnly
      end
    rescue BrownPaperTicketsImport::PreviewOnly
      self.messages << "#{@vouchers.length} orders found in import list"
      self.messages << "of which #{@existing_vouchers} are already in your database and won't be re-imported" if @existing_vouchers > 0
      self.messages << "#{@matched_customers} customers were found and/or updated" if @matched_customers > 0
      self.messages << "#{@created_customers} new customers will be created" if @created_customers > 0
      self.messages << "#{@created_showdates} show dates will be added" if @created_showdates > 0
      self.messages << "#{@created_vouchertypes} new vouchertypes will be created" if @created_vouchertypes > 0
    rescue BrownPaperTicketsImport::ShowNotFound
      self.errors.add_to_base("Couldn't find production name in spreadsheet")
    rescue Exception => e
      self.errors.add_to_base("Unexpected error: #{e.message}")
    end
    return @vouchers
  end
    
  def num_records
    (@vouchers.empty? ?
      @num_records ||= self.csv_rows.count { |row| content_row?(row) } :
      @vouchers.length)
  end

  def valid_records ; num_records ; end
  def invalid_records ; 0 ; end
  
  private

  def get_ticket_orders
    # production name is in cell A2; be sure "All Dates" is B2
    self.csv_rows.each do |row|
      find_or_create_show(row[0].to_s) and next if row[1].to_s == 'All Dates'
      if (content_row?(row) && (voucher = ticket_order_from_row(row)))
        @vouchers << voucher
        next
      end
    end
  end

  def find_or_create_show(name)
    if (s = Show.find_unique(name))
      @show = s
      self.messages << "Show '#{name}' already exists (id=#{s.id})"
    else
      @show = Show.create_placeholder!(name) 
      self.messages << "Show '#{name}' will be created"
    end
  end
  
  def content_row?(row) ; row[0].to_s =~ /^\s*[0-9]{7,}$/ ; end

  def ticket_order_from_row(row)
    raise(BrownPaperTicketsImport::ShowNotFound, "Invalid spreadsheet: no show name found, or spreadsheet may be correupted") unless @show

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
      @created_vouchertypes += 1
      vt = Vouchertype.create_external_voucher_for_season!(name, price, year.to_i) 
    end
    vt
  end

    
  def customer_from_row(row)
    # customer info columns:
    last_name,first_name = 4,5
    street,city,state,zip = 8,9,10,11
    day_phone,email = 13,14
    #  not used: shipping last/first name = 6,7 ; shipping country = 12
    customer = Customer.new(
      :first_name => row[first_name].to_s, :last_name => row[last_name].to_s,
      :street => row[street].to_s, :city => row[city].to_s, :state => row[state].to_s,
      :zip => row[zip].to_s,:day_phone => row[day_phone].to_s,:email => row[email].to_s)
    customer.force_valid = true
    if !Customer.find_unique(customer)  
      @created_customers += 1 
      customer = Customer.find_or_create!(customer)
    else
      @matched_customers += 1
    end
    customer
  end

  def showdate_from_row(row)
    event_date = Time.parse(row[2].to_s)
    unless (self.show.showdates &&
        sd = self.show.showdates.detect { |sd| sd.thedate == event_date })
      @created_showdates += 1
      sd = Showdate.placeholder(event_date)
      self.show.showdates << sd
    end
    sd
  end
      
end
