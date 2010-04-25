World(FixtureAccess)

Given /^I am not logged in$/ do
  visit '/logout'
end

Given /^I am logged in as (.*)?$/ do |who|
  admin = false
  case who
  when /nonsubscriber/
    @customer = customers(:tom)
  when /subscriber/
    pending
    @customer = customers(:tom)
    @customer.make_subscriber!
  when /box ?office manager/i
    @customer = customers(:boxoffice_manager)
    admin = true
  when /box ?office/i
    @customer = customers(:boxoffice_user)
    admin = true
  else
    @customer = customers(:generic_customer)
  end
  visit '/customers/login'
  fill_in :customer_login, :with => @customer.login
  fill_in :customer_password, :with => 'pass'
  click_button 'Login'
  response.should contain(Regexp.new("Welcome,.*#{@customer.first_name}"))
  response.should contain(Regexp.new("Logged in as Administrator")) if admin
end
