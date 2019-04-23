module CustomerLoginHelper
  def verify_successful_login
    # if someone is currently logged in, log them out first
    visit login_path
    return if page.has_content?("Log Out #{@customer.full_name}") # correct person already logged in
    visit logout_path if page.has_content?("Log Out")             # logout whoever's logged in
    visit login_path
    fill_in 'email', :with => @customer.email
    fill_in 'password', :with => @password
    click_button 'Login'
    expect(page).to have_content("Log Out #{@customer.full_name}")
    expect(page).to have_css('.adminField') if @is_admin
  end
end
World(CustomerLoginHelper)

Given /^I am not logged in$/ do
  visit logout_path
  page.should have_content("logged out")
end

Given /^I (am logged in|login) as (.*)?$/ do |_,who|
  @is_admin = false
  @password = 'pass'
  case who
  when /administrator/i then @customer,@password = Customer.find_by_role!(100),'admin'
  when /box ?office manager/i then @customer,@is_admin = create(:boxoffice_manager),true
  when /box ?office/i then @customer,@is_admin = create(:boxoffice),true
  when /staff/i         then @customer,@is_admin = create(:staff), true
  when /customer "(.*) (.*)"/ then @customer = find_or_create_customer $1,$2
  else raise "No such user '#{who}'"
  end
  verify_successful_login
end

Given /^customer "(.*) (.*)" has previously logged in$/ do |first,last|
  cust = find_customer(first,last)
  cust.update_attribute(:last_login, 1.second.ago)
  expect(cust.has_ever_logged_in?).to be_truthy
end

When /^I login with the correct credentials for customer "(.*) (.*)"$/ do |first,last|
  cust = find_customer(first,last)
  fill_in 'email', :with => cust.email
  fill_in 'password', :with => 'pass'
  click_button 'Login'
end

Then /^I should be able to login with username "(.*)" and (that password|password "(.*)")$/ do |username,use_prev,password|
  @password = password if use_prev !~ /that/
  @customer = Customer.where('email LIKE ?',username.downcase).first
  verify_successful_login
end

Then /(?:customer )"(.*) (.*)" should (not )?be logged in$/ do |first,last,no|
  @customer = find_customer first,last
  if no
    page.should_not have_content("Log Out #{@customer.full_name}")
  else
    page.should have_content("Log Out #{@customer.full_name}")
  end
end

