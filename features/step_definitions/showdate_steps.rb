World(FixtureAccess)

Given /^a performance (?:of "([^\"]+)" )?(?:at|on) (.*)(?: with (\d+) "(.*)" tickets available at \$(.*) each)?$/i do |name,time,qty,type,price|
  time = Time.parse(time)
  name ||= "New Show"
  @showdate = setup_show_and_showdate(name,time)
  if (qty)
    make_valid_tickets(@showdate, type, price.to_f, qty.to_i)
  end
end

Given /^today is (.*)$/i do |date|
  t = Time.parse(date)
  Time.stub!(:now).and_return(t)
  Date.stub!(:today).and_return(t)
end

Given /^(\d+ )?(.*) vouchers costing \$([0-9.]+) are available for this performance/i do |n,vouchertype,price|
  @showdate.should be_an_instance_of(Showdate)
  n = [n.to_i, 1].max           # in case n=0
  vt = Vouchertype.find_by_name!(vouchertype)
  vt.update_attribute(:price, price.to_f)
  @showdate.valid_vouchers.create!(:vouchertype => vt,
                                   :max_sales_for_type => n)
end
                                   
  
def setup_show_and_showdate(name,time,args={})
  show = Show.create!(:name => name,
    :house_capacity => args[:house_capacity] || 10,
    :opening_date => args[:opening_date] || Date.today,
    :closing_date => args[:closing_date] || Date.today)

  return show.showdates.create!(:thedate => time,
    :max_sales => args[:max_sales] || 100)
end



def make_valid_tickets(showdate,type,price,qty)
  qty ||= showdate.max_sales
  vt = create_generic_vouchertype(type,price)
  showdate.valid_vouchers.create!(:vouchertype => vt,
    :max_sales_for_type => qty.to_i)
end
    
  
def create_generic_vouchertype(type,price)
  Vouchertype.create!(:fulfillment_needed => false,
    :name => type,
    :category => 'revenue',
    :account_code => '9999',
    :price => price.to_f,
    :valid_date => Time.now - 1.month,
    :expiration_date => Time.now + 1.month)
end
