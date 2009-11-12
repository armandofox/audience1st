World(FixtureAccess)

Given /^I am not logged in$/ do
  visit '/logout'
end

Given /^I am logged in as (.*)?$/ do
  @customer = Customer.find(77)
  @customer.stub!(:update_attribute).and_return(true)
  case $1
  when /nonsubscriber/
    @customer.stub!(:is_subscriber?).and_return(false)
  when /subscriber/
    @customer.stub!(:is_subscriber?).and_return(true)
  when /box ?office/
    @customer.stub!(:is_boxoffice).and_return(true)
  end
  login_from_password(@customer)
end

