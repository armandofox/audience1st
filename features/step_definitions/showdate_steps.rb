Given /^(\d+) "(.*)" tickets available at \$(.*) each$/i do |qty,type,price|
  @showdate.should be_an_instance_of(Showdate)
  steps %Q{Given a "#{type}" vouchertype costing #{price} for the #{@showdate.season} season}
  make_valid_tickets(@showdate, @vouchertype, qty.to_i)
end

Given /^(\d+ )?(.*) vouchers costing \$([0-9.]+) are available for (?:this|that) performance/i do |n,vouchertype,price|
  @showdate.should be_an_instance_of(Showdate)
  steps %Q{Given a "#{vouchertype}" vouchertype costing $#{price} for the #{@showdate.season} season}
  make_valid_tickets(@showdate, @vouchertype, n.to_i)
end

Given /^(\d+) "(.*)" comps are available for "(.*)" on "([^\"]+)"(?: with promo code "(.*)")?$/ do |num,comp_type,show_name,date,code|
  show_date = Time.zone.parse(date)
  @showdate = setup_show_and_showdate(show_name,show_date)
  @comp = create(:comp_vouchertype, :name => comp_type, :season => show_date.year)
  @comp.update_attributes!(:offer_public => Vouchertype::ANYONE) if code
  make_valid_tickets(@showdate, @comp, num, code)
end
                                   
Given /^a performance (?:of "([^\"]+)" )?(?:at|on) (.*)$/ do |name,time|
  time = Time.zone.parse(time)
  name ||= "New Show"
  @showdate = setup_show_and_showdate(name,time)
  @show = @showdate.show
end

Given /^a show "(.*)" with the following tickets available:$/ do |show_name, tickets|
  tickets.hashes.each do |t|
    steps %Q{Given a show "#{show_name}" with #{t[:qty]} "#{t[:type]}" tickets for #{t[:price]} on "#{t[:showdate]}"}
  end
end

Given /^a show "(.*)" with the following performances: (.*)$/ do |name,dates|
  dates = dates.split(/\s*,\s*/).map {  |dt| Time.zone.parse(dt) }
  @show = create(:show, :name => name, :opening_date => dates.first)
  @showdates = dates.each { |d|  create(:showdate, :show => @show, :thedate => d) }
end

Then /^"(.*)" should have (\d+) showdates$/ do |show,num|
  Show.find_by_name!(show).showdates.count.should == num.to_i
end

Then /the showdate should have the following attributes:/ do |tbl|
  expect(@showdate).to be_a_kind_of Showdate
  @showdate.reload
  tbl.hashes.each do |attr|
    expect(@showdate.send(attr['attribute']).to_s).to eq(attr['value'].to_s)
  end
end

Then /^the following showdates for "(.*)" should exist:$/ do |showname,dates|
  show = Show.find_by_name!(showname)
  showdates = show.showdates
  dates.hashes.each do |date|
    sd = Showdate.find_by_thedate(Time.zone.parse(date[:date]))
    sd.should_not be_nil
    sd.show.should == show
    if date[:max_sales]
      sd.max_sales.should == date[:max_sales].to_i
    end
    if date[:sales_cutoff]
      sd.end_advance_sales.should == Time.zone.parse(date[:sales_cutoff])
    end
  end
end

When /^I delete the showdate "(.*)"$/ do |date|
  showdate = Showdate.find_by_thedate!(Time.zone.parse date)
  steps %Q{When I visit the show details page for "#{showdate.show.name}"}
  click_button "delete_showdate_#{showdate.id}"
end

Then /^there should be no "Delete" button for the showdate "(.*)"$/ do |date|
  showdate = Showdate.find_by_thedate!(Time.zone.parse date)
  page.should_not have_xpath("//tr[@id='showdate_#{showdate.id}']//input[@type='submit' and @value='Delete']")
end

Then /^there should be no show on "(.*)"$/ do |date|
  Showdate.find_by_thedate(Time.zone.parse date).should be_nil
end

Then /^the (.*) performance should be oversold( by (\d+))?$/ do |date, _, num|
  showdate = Showdate.find_by_thedate! Time.zone.parse(date)
  num = num.to_i
  if num > 0
    (showdate.compute_total_sales - showdate.max_sales).should == num
  else
    showdate.compute_total_sales.should be > showdate.max_sales
  end
end

Given /^(that|the "(.*)") performance is sold out$/ do |recent,dt|
  if recent =~ /that/
    showdate = @showdate
    dt = showdate.thedate
  else
    showdate = Showdate.find_by_thedate!(Time.zone.parse(dt))
  end
  to_sell = showdate.max_sales - showdate.compute_total_sales
  vtype = create(:valid_voucher, :showdate => showdate).name
  steps %Q{Given #{to_sell} "#{vtype}" tickets have been sold for "#{dt}"}
end

#  @showdate is set by the function that most recently created a showdate for a scenario

Given /^sales cutoff at "(.*)", with "(.*)" tickets selling from (.*) to (.*)$/ do |end_advance_sales, vouchertype_name, start_sales, end_sales|
  vtype = Vouchertype.find_by_name!(vouchertype_name)
  vtype.valid_vouchers = []
  vtype.valid_vouchers <<
    ValidVoucher.new(
    :showdate => @showdate,
    :start_sales => Time.zone.parse(start_sales),
    :end_sales   => Time.zone.parse(end_sales)
    )
  @showdate.update_attributes!(:end_advance_sales => end_advance_sales)
end

Given /^there are (\d+) "(.*)" tickets and (\d+) total seats available$/ do |per_ticket_limit, vouchertype_name, seat_limit|
  vtype = Vouchertype.find_by_name!(vouchertype_name)
  vtype.valid_vouchers = []
  vtype.valid_vouchers <<
    ValidVoucher.new(
    :showdate => @showdate,
    :start_sales => 1.week.ago,
    :end_sales   => @showdate.thedate,
    :max_sales_for_type => per_ticket_limit
    )
  @showdate.update_attributes!(:max_sales => seat_limit)
end
