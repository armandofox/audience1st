World(FixtureAccess)
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

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

Given /^I am acting on behalf of customer "(.*) (.*)"$/ do |first,last|
  customer = Customer.find_by_first_name_and_last_name!(first,last)
  find(:xpath, "//input[@id='id']").set customer.id # must use xpath since hidden field
  with_scope('form#quick_search') do ;  click_button 'Go' ;  end
  with_scope('div#on_behalf_of_customer') do
    page.should have_content("Customer: #{first} #{last}")
  end
end

Then /^I should be able to login with username "(.*)" and that password$/ do |username|
  steps %Q{Then I should be able to login with username "#{username}" and password "#{@password}"}
end

Then /^I should be able to login with username "(.*)" and password "(.*)"$/ do |username,password|
  visit '/logout'
  visit '/sessions/new'
  customer = Customer.find_by_email(username)
  fill_in 'email', :with => username
  fill_in 'password', :with => password
  click_button 'Login'
  page.should have_content("Welcome, #{customer.first_name}")
end

Given /^customer "(.*) (.*)" should exist$/ do |first,last|
  @customer = Customer.find_by_first_name_and_last_name!(first,last)
end

Given /^customer "(.*) (.*)" exists$/ do |first,last|
  @customer =
    Customer.find_by_first_name_and_last_name(first,last) ||
    BasicModels.create_generic_customer(:first_name => first, :last_name => last)
end

Given /^my birthday is set to "(.*)"/ do |date|
  @customer.update_attributes!(:birthday => Date.parse(date))
end

Then /^customer "(.*) (.*)" should have a birthday of "(.*)"$/ do |first,last,date|
  Customer.find_by_first_name_and_last_name!(first,last).birthday.should ==
    Date.parse(date).change(:year => Customer::BIRTHDAY_YEAR)
end


Given /^customer "(.*) (.*)" has secret question "(.*)" with answer "(.*)"$/ do |first,last,question,answer|
  @customer = Customer.find_by_first_name_and_last_name!(first,last)
  @customer.update_attributes(
    :secret_question => get_secret_question_index(question),
    :secret_answer => answer)
end


Then /^customer "(.*) (.*)" should have secret question "(.*)" with answer "(.*)"$/ do |first,last,question,answer|
  @customer = Customer.find_by_first_name_and_last_name!(first,last)
  @customer.secret_question.should == get_secret_question_index(question)
  @customer.secret_answer.should == answer
end

def get_secret_question_index(question)
  indx = APP_CONFIG[:secret_questions].index(question)
  indx.should be_between(0, APP_CONFIG[:secret_questions].length-1)
  indx
end
