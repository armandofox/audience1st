DEFAULT_HOUSE_CAPACITY = 100

Given /^there are no shows set up$/ do
  Show.delete_all
end

Given /^there is no show named "(.*)"$/ do |name|
  Show.find_by_name(name).should be_nil
end

Given /^there is a show named "(.*)" opening (.*)$/ do |name,opening|
  @show = Show.create!(:name => name,
    :opening_date => Date.parse(opening),
    :closing_date => Date.parse(opening) + 1.month,
    :house_capacity => DEFAULT_HOUSE_CAPACITY,
    :listing_date => Date.today)
end

Given /^there is a show named "(.*)"$/ do |name|
  @show =  Show.find_by_name(name) ||
    Show.create!(:name => name,
    :opening_date => Date.today,
    :closing_date => Date.today + 1.week,
    :house_capacity => DEFAULT_HOUSE_CAPACITY,
    :listing_date => Date.today)
end

When /^I specify a show "(.*)" playing from "(.*)" until "(.*)" with capacity "(.*)" to be listed starting "(.*)"/i do |name,opens,closes,cap,list|
  fill_in "Show Name", :with => name
  select_date(eval(opens), :from => "Opens")
  select_date(eval(closes), :from => "Closes")
  fill_in "Actual house capacity", :with => cap
  select_date(eval(list), :from => "List starting")

end
