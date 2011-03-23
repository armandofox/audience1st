World(FixtureAccess)
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

Given /^I am not logged in$/ do
  visit '/logout'
  response.should contain(/logged out/i)
end

Given /^I am logged in as (.*)?$/ do |who|
  is_admin = false
  case who
  when /administrator/i
    @customer = customers(:admin)
  when /nonsubscriber/i
    @customer = customers(:tom)
  when /subscriber/i
    @customer = customers(:tom)
    make_subscriber!(@customer)
  when /box ?office manager/i
    @customer = customers(:boxoffice_manager)
    is_admin = true
  when /box ?office/i
    @customer = customers(:boxoffice_user)
    is_admin = true
  when /staff/i
    @customer = customers(:staff)
    is_admin = true
  when /customer "(.*) (.*)"/
    @customer = Customer.find_by_first_name_and_last_name!($1,$2)
  else
    raise "No such user '#{who}'"
  end
  visit logout_path
  visit login_path
  fill_in 'email', :with => @customer.email
  fill_in 'password', :with => 'pass'
  click_button 'Login'
  response.should contain(Regexp.new("Welcome,.*#{@customer.first_name}"))
  response.should have_selector('div[id=customer_quick_search].adminField') if is_admin
end

Given /^customer "(.*) (.*)" (should )?exists?$/ do |first,last,flag|
  @customer = Customer.find_by_first_name_and_last_name(first,last)
  @customer.should_not be_nil
end
