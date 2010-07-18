class BrownPaperTicketsImport < Import

  attr_accessor :show, :created_customers, :created_showdates

  def initialize
    @created_customers = 0
    @created_showdates = 0
    @show = nil
  end

  def preview
    self.pretend = true
    get_ticket_orders
  end

  def get_ticket_orders
    # production name is in cell A2; be sure "All Dates" is B2
    self.csv_rows.each do |row|
      find_or_create_show(row[0].to_s) and next if row[1].to_s == 'All Dates'
      @ticket_orders << ticket_order_from_row(row) and next if content_row?(row)
    end
  end

  private

  def find_or_create_show(name)
    if (s = Show.find_unique(name))
      @show = s
      self.messages << "Show '#{name}' already exists (id=#{s.id})"
    else
      @show = Show.placeholder(name) unless pretend
      self.messages << "Show '#{name}' will be created"
    end
  end
  
  def content_row?(row) ; row[0].to_s =~ /^\s*\d{7,}$/ ; end

  def ticket_order_from_row(row)
    self.messages << "Invalid spreadsheet: no show name found, or spreadsheet may be correupted" and return unless @show
    # content columns:
    ticket_id = 0         #  (7 or more digits)
    order_date = 1        # use for created_on
    #  event_end_date (not used)
    # card number masked to last 4 digits, box office user, order notes (not used)
    vouchertype_name,price = 18,19

    customer = customer_from_row(row)
    showdate = showdate_from_row(row)
    
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
      customer = Customer.find_or_create!(customer) unless @pretend
    end
    customer
  end

  def showdate_from_row(row)
    event_date = Time.parse(row[2].to_s)
    if (self.show.showdates &&
        sd = self.show.showdates.detect { |sd| sd.thedate == event_date })
      sd
    else
      @created_showdates += 1
      Showdate.placeholder(event_date)
    end
  end
      
end
