World(ScenarioHelpers::Orders)

Given /^there is no show named "([^\"]+)"$/ do |name|
  expect(Show.find_by(:name => name)).to be_nil
end

Given /^a show "(.*)" with tickets on sale for today$/ do |name|
  steps %Q{
    Given a performance of "#{name}" at #{Time.current + 8.hours}
    Given 10 General vouchers costing $20 are available for that performance
  }
end

Given /^show "(.*)" (has|should have) description "(.*)"$/ do |name,exists,desc|
  if exists
    Show.find_by_name!(name).update_attributes!(:description => desc)
  else
    expect(Show.find_by_name!(name).description).to eq(desc)
  end
end

Given /^a class "(.*)" available for enrollment now$/ do |name|
  steps %Q{Given a show "#{name}" with tickets on sale for today}
  @show.update_attributes!(:event_type => "Class")
end

Given /^there is a show named "([^\"]+)"$/ do |name|
  @show = create(:show, :name => name)
end

Given /^there is a show named "(.*)" with showdates:$/ do |name,showdates|
  @show = create(:show, :name => name)
  showdates.hashes.each do |showdate|
    s = create(:showdate, :show => @show, :thedate => Time.zone.parse(showdate[:date]))
    showdate[:tickets_sold].to_i.times { create(:revenue_voucher, :showdate => s) }
  end
end

Given /^a performance (?:of "([^\"]+)" )?(?:at|on) (.*)$/ do |name,time|
  time = Time.zone.parse(time)
  name ||= "New Show"
  @showdate = setup_show_and_showdate(name,time)
  @show = @showdate.show
end

Given /^a show "(.*)" with the following performances: (.*)$/ do |name,dates|
  dates = dates.split(/\s*,\s*/).map {  |dt| Time.zone.parse(dt) }
  @show = create(:show, :name => name, :season => dates.first.year)
  @showdates = dates.each { |d|  create(:showdate, :show => @show, :thedate => d) }
end

Then /^"(.*)" should have (\d+) showdates$/ do |show,num|
  Show.find_by_name!(show).showdates.count.should == num.to_i
end

Then /the show "(.*)" should have the following attributes:/ do |name,tbl|
  show = Show.find_by!(:name => name)
  tbl.hashes.each do |attr|
    val = attr['value']
    expected_val =
      if val =~ /^\d{4}-\d\d-\d\d$/ then Date.parse val
      elsif val =~ /^\d{4}-\d\d-\d\d\b/ then Time.zone.parse val
      elsif val =~ /^[0-9.]+$/ then val.to_f
      else val
      end
    expect(show.send attr['attribute']).to eq(expected_val)
  end
end

Then /the ("(.*)" )?showdate should have the following attributes:/ do |thedate,tbl|
  if (thedate)
    @showdate = Showdate.find_by!(:thedate => Time.zone.parse(thedate))
  else
    expect(@showdate).to be_a_kind_of Showdate
  end
  @showdate.reload
  tbl.hashes.each do |attr|
    val = attr['value']
    expected_val =
      if val =~ /^\d{4}-\d\d-\d\d$/ then Date.parse val
      elsif val =~ /^\d{4}-\d\d-\d\d\b/ then Time.zone.parse val
      elsif val =~ /^[0-9.]+$/ then val.to_f
      else val
      end
    expect(@showdate.send(attr['attribute'])).to eq(expected_val)
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
      sd.max_advance_sales.should == date[:max_sales].to_i
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

Then /^the (.*) performance should be oversold( by (\d+))?$/ do |date, num|
  showdate = Showdate.find_by_thedate! Time.zone.parse(date)
  num = num.to_i
  if num > 0
    (showdate.total_sales.size - showdate.max_advance_sales).should == num
  else
    showdate.total_sales.size.should be > showdate.max_advance_sales
  end
end

Given /^the "(.*)" performance (has reached its max sales|is truly sold out)$/ do |dt,sold|
  showdate = Showdate.find_by(:thedate => Time.zone.parse(dt))
  to_sell = (sold =~ /max/ ? showdate.saleable_seats_left : showdate.total_seats_left)
  to_sell.times { create(:revenue_voucher, :showdate => showdate, :finalized => true) }
  # also create a valid_voucher that reflects the tickets that just got sold out, since
  # that info is used to populate ticket menus on sales pages
  create(:valid_voucher, :showdate => showdate)
end

#  @showdate is set by the function that most recently created a showdate for a scenario

Given /^"(.*)" tickets selling from (.*) to (.*)$/ do |vouchertype_name, start_sales, end_sales|
  vtype = Vouchertype.find_by_name!(vouchertype_name)
  vtype.valid_vouchers = []
  vtype.valid_vouchers <<
    ValidVoucher.new(
    :showdate => @showdate,
    :start_sales => Time.zone.parse(start_sales),
    :end_sales   => Time.zone.parse(end_sales)
    )
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
  @showdate.update_attributes!(:max_advance_sales => seat_limit)
end

# Types of showdates: GA in theater, RS in theater, live stream, stream anytime

# After making changes - need to reload the AR objects that have been instance variables throughout
# the scenario
Then /the "(.*)" performance should use the "(.*)" seatmap/ do |thedate,name|
  @showdate = Showdate.find_by!(:thedate => Time.zone.parse(thedate))
  steps %Q{Then that performance should use the "#{name}" seatmap}
end

Then /that performance should use the "(.*)" seatmap/ do |name|
  expect(@showdate.reload.seatmap.name).to eq(name)
end

Then /the "(.*)" performance should be General Admission/ do |thedate|
  @showdate = Showdate.find_by!(:thedate => Time.zone.parse(thedate))
  expect(@showdate.seatmap).to be_blank
end

Then /that performance should be General Admission/ do
  expect(@showdate.reload.seatmap).to be_blank
end

Then /the "(.*)" performance should be (Stream Anytime|Live Stream)/ do |thedate,type|
  @showdate = Showdate.find_by!(:thedate => Time.zone.parse(thedate))
  if type =~ /anytime/i
    expect(@showdate.stream_anytime).to be_truthy
    expect(@showdate.live_stream).to be_falsy
  else
    expect(@showdate.stream_anytime).to be_falsy
    expect(@showdate.live_stream).to be_truthy
  end
end
