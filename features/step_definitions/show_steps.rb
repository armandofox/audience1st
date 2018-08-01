Given /^there are no shows set up$/ do
  Show.delete_all
end

Given /^there is no show named "([^\"]+)"$/ do |name|
  Show.find_by_name(name).should be_nil
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
  @show =  Show.find_by_name(name) ||
    create(:show, :name => name,
    :opening_date => Date.today, :closing_date => Date.today + 1.week)
end

Given /^there is a show named "([^\"]+)" opening "([^\"]+)"$/ do |name,opening|
  @show = create(:show, :name => name,
    :opening_date => Date.parse(opening))
end

Given /^there is a show named "([^\"]+)" opening "([^\"]+)" and closing "([^\"]+)"$/ do |name,opening,closing|
  @show = create(:show, :name => name,
    :opening_date => Date.parse(opening),
    :closing_date => Date.parse(closing))
end

Given /^there is a show named "(.*)" with showdates:$/ do |name,showdates|
  @show = create(:show, :name => name)
  showdates.hashes.each do |showdate|
    s = create(:showdate, :show => @show, :thedate => Time.zone.parse(showdate[:date]))
    showdate[:tickets_sold].to_i.times { create(:revenue_voucher, :showdate => s) }
  end
end

# Given /^the following shows exist:$/ do |shows|
#   shows.hashes.each do |show|
#     %Q{Given there is a show named "#{show[:name]}" opening "#{show[:opens]}" and closing "#{show[:closes]}"}
#   end
# end

When /^I specify a show "(.*)" playing from "(.*)" until "(.*)" with capacity "(.*)" to be listed starting "(.*)"/i do |name,opens,closes,cap,list|
  fill_in "Show Name", :with => name
  select_date_from_dropdowns(eval(opens), :from => "Opens")
  select_date_from_dropdowns(eval(closes), :from => "Closes")
  fill_in "Actual house capacity", :with => cap
  select_date_from_dropdowns(eval(list), :from => "List starting")

end
