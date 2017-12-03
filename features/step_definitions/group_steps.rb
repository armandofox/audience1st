Given /I enter the groups url/ do
  visit "/groups"
end


When(/^I select "([^"]*)" tab$/) do |tab_name|
  pending
end

And(/^I select customers "(.*) (.*)" and "(.*) (.*)" to add to groups$/) do |f1,l1,f2,l2|
  c1 = find_or_create_customer f1,l1
  c2 = find_or_create_customer f2,l2
  visit customers_path
  check "merge[#{c1.id}]"
  check "merge[#{c2.id}]"
end

And(/^I select groups "([^"]*)"$/) do |groups|
  pending
end

Then(/^I will have a group "([^"]*)" with members "([^"]*)"$/) do |group, members|
  pending
end