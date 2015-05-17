World(FixtureAccess)
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

module CustomerStepsHelper
  def get_secret_question_index(question)
    indx = APP_CONFIG[:secret_questions].index(question)
    indx.should be_between(0, APP_CONFIG[:secret_questions].length-1)
    indx
  end
end
World(CustomerStepsHelper)

Then /^account creation should fail with "(.*)"$/ do |msg|
  steps %Q{
  Then I should see "#{msg}"
  And I should see "Create Your Account"
}
end

Given /^I am not logged in$/ do
  visit logout_path
  page.should have_content("logged out")
end

Given /^I am logged in as (.*)?$/ do |who|
  visit logout_path
  visit login_path
  steps %Q{When I login as #{who}}
  page.should have_content("Welcome, #{@customer.first_name}")
  page.should have_css('#customer_quick_search') if @is_admin
end

When /^I login as (.*)$/ do |who|
  @is_admin = false
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
    @is_admin = true
  when /box ?office/i
    @customer = customers(:boxoffice_user)
    @is_admin = true
  when /staff/i
    @customer = customers(:staff)
    @is_admin = true
  when /customer "(.*) (.*)"/
    @customer = Customer.find_by_first_name_and_last_name!($1,$2)
  else
    raise "No such user '#{who}'"
  end
  fill_in 'email', :with => @customer.email
  fill_in 'password', :with => 'pass'
  click_button 'Login'
end

Given /^I (?:am acting on behalf of|switch to) customer "(.*) (.*)"$/ do |first,last|
  customer = Customer.find_by_first_name_and_last_name!(first,last)
  visit customer_path(customer)
  with_scope('div#on_behalf_of_customer') do
    page.should have_content("Customer: #{first} #{last}")
  end
end

Then /^I should be acting on behalf of customer "(.*)"$/ do |full_name|
  with_scope('#onBehalfOfName') do
    page.should have_content(full_name)
  end
end

Then /^I should be able to login with username "(.*)" and (that password|password "(.*)")$/ do |username,use_prev,password|
  @password = password if use_prev !~ /that/
  visit logout_path
  visit login_path
  customer = Customer.find_by_email(username)
  fill_in 'email', :with => username
  fill_in 'password', :with => @password
  click_button 'Login'
  page.should have_content("Welcome, #{customer.first_name}")
end

Given /^customer "(.*) (.*)" should (not )?exist$/ do |first,last,no|
  @customer = Customer.find_by_first_name_and_last_name(first,last)
  if no then @customer.should be_nil else @customer.should be_a_kind_of Customer end
end

Given /^customer "(.*) (.*)" exists$/ do |first,last|
  @customer =
    Customer.find_by_first_name_and_last_name(first,last) ||
    create(:customer, :first_name => first, :last_name => last)
end

Given /^the following customers exist: (.*)$/ do |list|
  list.split(/\s*,\s*/).each do |name|
    steps %Q{Given customer "#{name}" exists}
  end
end

# Searching for customers

When /^I search any field for "(.*)"$/ do |text|
  visit customers_path
  fill_in "customers_filter", :with => text
  with_scope '#search_on_any_field' do ; click_button 'Go' ; end
end

Given /^my birthday is set to "(.*)"/ do |date|
  @customer.update_attributes!(:birthday => Date.parse(date))
end

Then /^customer "(.*) (.*)" should have the following attributes:$/ do |first,last,attribs|
  customer = Customer.find_by_first_name_and_last_name! first,last
  dummy = Customer.new
  attribs.hashes.each do |attr|
    name,val = attr[:attribute], attr[:value]
    customer.send(name).should == Customer.columns_hash[name].type_cast(val)
  end
end

Then /^customer "(.*) (.*)" should have a birthday of "(.*)"$/ do |first,last,date|
  Customer.find_by_first_name_and_last_name!(first,last).birthday.should ==
    Date.parse(date).change(:year => Customer::BIRTHDAY_YEAR)
end

When /^I select customers "(.*) (.*)" and "(.*) (.*)" for merging$/ do |f1,l1, f2,l2|
  c1 = Customer.find_by_first_name_and_last_name! f1,l1
  c2 = Customer.find_by_first_name_and_last_name! f2,l2
  visit customers_path
  check "merge[#{c1.id}]"
  check "merge[#{c2.id}]"
end

Given /^customer "(.*) (.*)" (should have|has) secret question "(.*)" with answer "(.*)"$/ do |first,last,assert,question,answer|
  @customer = Customer.find_by_first_name_and_last_name!(first,last)
  if assert =~ /should/
    @customer.secret_question.should == get_secret_question_index(question)
    @customer.secret_answer.should == answer
  else
    @customer.update_attributes(
      :secret_question => get_secret_question_index(question),
      :secret_answer => answer)
  end
end
