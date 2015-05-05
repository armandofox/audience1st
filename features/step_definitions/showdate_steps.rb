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

Given /^(\d+) "(.*)" comps are available for "(.*)" on "(.*)"$/ do |num,comp_type,show_name,show_date|
  @showdate = setup_show_and_showdate(show_name,Time.parse(show_date))
  @comp = BasicModels.create_comp_vouchertype(:name => comp_type)
  make_valid_tickets(@showdate, @comp, num)
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

When /^I delete the showdate "(.*)"$/ do |date|
  showdate = Showdate.find_by_thedate!(Time.parse date)
  steps %Q{When I visit the show details page for "#{showdate.show.name}"}
  within("#showdate_#{showdate.id}") { click_button "Delete" }
end

Then /^there should be no "Delete" button for the showdate "(.*)"$/ do |date|
  showdate = Showdate.find_by_thedate!(Time.parse date)
  page.should_not have_xpath("//tr[@id='showdate_#{showdate.id}']//input[@type='submit' and @value='Delete']")
end

Then /^there should be no show on "(.*)"$/ do |date|
  Showdate.find_by_thedate(Time.parse date).should be_nil
end
