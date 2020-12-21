# Fill in fields for gift, checkout, etc

When /^I fill in the "(.*)" fields with "(\S+)\s+(\S+),\s*([^,]+),\s*([^,]+),\s*(\S+)\s+(\S+),\s*([^,]+),\s*(.*@.*)"$/ do |fieldset, first, last, street, city, state, zip, phone, email|
  with_scope fieldset do
    fill_in 'customer[first_name]', :with => first
    fill_in 'customer[last_name]', :with => last
    fill_in 'customer[street]', :with => street
    fill_in 'customer[city]', :with => city
    fill_in 'customer[state]', :with => state
    fill_in 'customer[zip]', :with => zip
    fill_in 'customer[day_phone]', :with => phone
    fill_in 'customer[email]', :with => email
  end
end

When /^I fill in the address as "(.*),\s*(.*),\s*(.*)\s+(.*)"/ do |street,city,state,zip|
  with_scope "#street_city_only" do
    fill_in 'customer[street]', :with => street
    fill_in 'customer[city]', :with => city
    fill_in 'customer[state]', :with => state
    fill_in 'customer[zip]', :with => zip
  end
end

When /^I proceed to checkout/ do
  #click_button 'submit'
  find('input#submit').click
end

When /^I try to checkout as guest using "(.*)"$/ do |info|
  steps %Q{
  When I follow "Checkout as Guest"
  And I fill in the ".billing_info" fields with "#{info}"
}
end

When /^I successfully complete guest checkout$/ do
  find('input#submit').click
  steps %Q{
And I place my order with a valid credit card
}
end

Then /^the gift recipient customer should be "(.*)\s+(.*)"$/ do |first,last|
  verify_customer_in_div "#gift_recipient", first, last
end

Then /^the billing customer should be "(.*)\s+(.*)"$/ do |first,last|
  within('#purchaser') { page.should have_content("#{first} #{last}") }
end

