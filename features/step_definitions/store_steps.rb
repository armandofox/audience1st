World()

Given /^(.*) has an account with login (.*)$/ do |var,login|
  c = Customer.find_by_login(login)
  c.should be_a_kind_of(Customer)
  instance_variable_set("@#{var}", c)
end

When /^I visit the Store page$/i do
  visit '/store'
end

Then /^I should see the (.*) message$/ do |m|
  response.should have_selector("div.storeBanner#{m}")
end
