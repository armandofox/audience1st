Given /^(\d+) "(.*)" tickets available at \$(.*) each$/i do |qty,type,price|
  @showdate.should be_an_instance_of(Showdate)
  step %Q{a "#{type}" vouchertype costing #{price} for the #{@showdate.season} season}
  make_valid_tickets(@showdate, @vouchertype, qty.to_i)
end

Given /^(\d+ )?(.*) vouchers costing \$([0-9.]+) are available for (?:this|that) performance/i do |n,vouchertype,price|
  @showdate.should be_an_instance_of(Showdate)
  step %Q{a "#{vouchertype}" vouchertype costing $#{price} for the #{@showdate.season} season}
  make_valid_tickets(@showdate, @vouchertype, n.to_i)
end
                                   
Given /^a performance (?:of "([^\"]+)" )?(?:at|on) (.*)$/ do |name,time|
  time = Time.parse(time)
  name ||= "New Show"
  @showdate = setup_show_and_showdate(name,time)
  @show = @showdate.show
end

Then /^"(.*)" should have (\d+) showdates$/ do |show,num|
  Show.find_by_name!(show).showdates.count.should == num.to_i
end

Then /^the following showdates for "(.*)" should exist:$/ do |showname,dates|
  show = Show.find_by_name!(showname)
  showdates = show.showdates
  dates.hashes.each do |date|
    sd = Showdate.find_by_thedate(Time.parse(date[:date]))
    sd.should_not be_nil
    sd.show.should == show
    if date[:max_sales]
      sd.max_sales.should == date[:max_sales].to_i
    end
    if date[:sales_cutoff]
      sd.end_advance_sales.should == Time.parse(date[:sales_cutoff])
    end
  end
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



def make_valid_tickets(showdate,vtype,qty=nil)
  qty ||= showdate.max_allowed_sales
  showdate.valid_vouchers.create!(:vouchertype => vtype,
    :max_sales_for_type => qty.to_i,
    :end_sales => showdate.thedate + 5.minutes,
    :start_sales => [Time.now - 1.day, showdate.thedate - 1.week].min
    )
end
