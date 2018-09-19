module CustomerLoginHelper
  def verify_successful_login
    visit logout_path
    visit login_path
    fill_in 'email', :with => @customer.email
    fill_in 'password', :with => @password
    click_button 'Login'
    page.should have_content("Signed in as #{@customer.first_name}")
    page.should have_css('#customer_quick_search') if @is_admin
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


Then /^I should be able to login with username "(.*)" and (that password|password "(.*)")$/ do |username,use_prev,password|
  @password = password if use_prev !~ /that/
  @customer = Customer.where('email LIKE ?',username.downcase).first
  verify_successful_login
end

Then /(?:customer )"(.*) (.*)" should (not )?be logged in$/ do |first,last,no|
  @customer = find_customer first,last
  if no
    page.should_not have_content("Signed in as #{@customer.full_name}")
  else
    page.should have_content("Signed in as #{@customer.full_name}")
  end
end

