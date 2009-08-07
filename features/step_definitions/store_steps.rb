World(FixtureAccess)

Given /^I am not logged in$/ do
  visit '/logout'
end

Given /^I am logged in as a subscriber$/ do
  @customer = Customer.find(77)
  @customer.stub!(:is_subscriber?).and_return(false)
  @customer.stub!(:update_attribute).and_return(true)
  login_from_password(@customer)
end

Given /^I am logged in as a nonsubscriber$/ do
  @customer = Customer.find(77)
  @customer.stub!(:is_subscriber?).and_return(true)
  @customer.stub!(:update_attribute).and_return(true)
  login_from_password(@customer)
end

When /^I visit the Store page$/i do
  visit '/store'
end

Then /^I should see the (.*) message$/ do |m|
  response.should have_selector("div.storeBanner#{m}")
end
