Given /I enter the groups url/ do
  visit "/groups"
end


When(/^I select "([^"]*)" tab$/) do |tab_name|
  pending
end

And(/^I select customers "([^"]*)" to add to groups$/) do |customers|
  visit customers_path
  list = customers.split(', ')
  list.each { |name|
    m = /^(.*) (.*)$/.match(name)
    # m[1] is the first name and m[2] is the last name
    c = find_or_create_customer m[1], m[2]
    check "merge[#{c.id}]"
  }
end

And(/^I select groups "([^"]*)"$/) do |groups|
  pending
end

Then(/^I will have a group "([^"]*)" with members "([^"]*)"$/) do |group, members|
  pending
end