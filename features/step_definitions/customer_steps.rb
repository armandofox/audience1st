World(FixtureAccess)
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

Then /^account creation should fail with "(.*)"$/ do |msg|
  Then %Q{I should see "#{msg}"}
  And %Q{I should see "Create Your Account"}
end

Given /^I am not logged in$/ do
  visit logout_path
  page.should have_content("logged out")
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
  visit '/logout'
  visit '/sessions/new'
  fill_in 'email', :with => @customer.email
  fill_in 'password', :with => 'pass'
  click_button 'Login'
  page.should have_content("Welcome, #{@customer.first_name}")
  page.should have_css('#customer_quick_search') if is_admin
end

Then /^I should be able to login with username "(.*)" and that password$/ do |username|
  Then %Q{I should be able to login with username "#{username}" and password "#{@password}"}
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
    Customer.create!(:first_name => first, :last_name => last,
    :email => "#{first}_#{last}_#{rand(1000)}@yahoo.com")
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
