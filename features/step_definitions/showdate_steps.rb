World()



Given /^(\d+) "(.*)" tickets available at \$(.*) each$/i do |qty,type,price|
  @showdate.should be_an_instance_of(Showdate)
  make_valid_tickets(@showdate, type, price.to_f, qty.to_i)
end

Given /^a performance (?:of "([^\"]+)" )?(?:at|on) (.*)$/ do |name,time|
  time = Time.parse(time)
  name ||= "New Show"
  @showdate = setup_show_and_showdate(name,time)
end
  
Given /^(\d+ )?(.*) vouchers costing \$([0-9.]+) are available for this performance/i do |n,vouchertype,price|
  @showdate.should be_an_instance_of(Showdate)
  vt = BasicModels.create_revenue_vouchertype(:name => vouchertype,
    :season => @showdate.thedate.year,
    :price => price
    )
  @showdate.valid_vouchers.create!(:vouchertype => vt,
    :max_sales_for_type => [n.to_i, 1].max,           # in case n=0
    :start_sales => @showdate.thedate - 1.month,
    :end_sales => @showdate.thedate - 5.minutes)
end
                                   
  
def setup_show_and_showdate(name,time,args={})
  show = Show.find_by_name(name) ||
    Show.create!(:name => name,
    :house_capacity => args[:house_capacity] || 10,
    :opening_date => args[:opening_date] || 1.month.ago,
    :closing_date => args[:closing_date] || 1.month.from_now)

  return Showdate.find_by_show_id_and_thedate(show.id, time) ||
    show.showdates.create!(
    :thedate => time,
    :end_advance_sales => time - 5.minutes,
    :max_sales => args[:max_sales] || 100)
end



def make_valid_tickets(showdate,type,price,qty=nil)
  qty ||= showdate.max_allowed_sales
  vt = create_generic_vouchertype(type,price)
  showdate.valid_vouchers.create!(:vouchertype => vt,
    :max_sales_for_type => qty.to_i,
    :start_sales => 1.day.ago,
    :end_sales => 1.day.from_now)
end
    
  
def create_generic_vouchertype(type,price)
  Vouchertype.create!(:fulfillment_needed => false,
    :name => type,
    :category => 'revenue',
    :account_code => AccountCode.default_account_code,
    :offer_public => Vouchertype::ANYONE,
    :price => price.to_f,
    :season => Time.this_season)
end
