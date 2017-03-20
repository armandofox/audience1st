module CustomerLoginHelper
  def verify_successful_login(username,pass,admin=false)
    visit logout_path
    visit login_path
    fill_in 'email', :with => @customer.email
    fill_in 'password', :with => pass
    click_button 'Login'
    page.should have_content("Signed in as #{@customer.first_name}")
    page.should have_css('#customer_quick_search') if admin
  end
end
World(CustomerLoginHelper)

Given /^I am not logged in$/ do
  visit logout_path
  page.should have_content("logged out")
end

Given /^I (am logged in|login) as (.*)?$/ do |_,who|
  is_admin = false
  case who
  when /administrator/i then customer = Customer.find_by_role!(100)
  when /nonsubscriber/i then customer = customers(:tom)
  when /subscriber/i    then make_subscriber!(customer = customers(:tom))
  when /box ?office manager/i then customer,is_admin = customers(:boxoffice_manager),true
  when /box ?office/i   then customer,is_admin = customers(:boxoffice_user),true
  when /staff/i         then customer,is_admin = customers(:staff),true
  when /customer "(.*) (.*)"/ then customer = Customer.find_by_first_name_and_last_name!($1,$2)
  else raise "No such user '#{who}'"
  end
  verify_successful_login(customer.email, 'pass', is_admin)
end


Then /^I should be able to login with username "(.*)" and (that password|password "(.*)")$/ do |username,use_prev,password|
  @password = password if use_prev !~ /that/
  customer = Customer.find(:first, :conditions => ['email LIKE ?',username.downcase])
  verify_successful_login(username, @password)
end
