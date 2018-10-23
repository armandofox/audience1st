module CustomerDivs
  def verify_customer_in_div(id, first, last)
    with_scope id do
      find_field("customer[first_name]").value.should == first
      find_field("customer[last_name]").value.should == last
    end
  end
end

World(CustomerDivs)

Given /^a show "(.*)" with "(.*)" tickets for \$?(.*) on "(.*)"$/ do |show,type,price,date|
  steps %Q{Given a show "#{show}" with 100 "#{type}" tickets for $#{price} on "#{date}"}
end

Given /^a show "(.*)" with (\d+) "(.*)" tickets for \$(.*) on "(.*)"$/ do |show,num,type,price,date|
  steps %Q{Given a performance of "#{show}" on "#{date}"
           And #{num} #{type} vouchers costing $#{price} are available for that performance}
end

Given /^the "(.*)" tickets for "(.*)" require promo code "(.*)"$/ do |ticket_type,date,promo|
  vouchertype = Vouchertype.find_by_name! ticket_type
  showdate = Showdate.find_by_thedate! Time.zone.parse date
  ValidVoucher.find_by_vouchertype_id_and_showdate_id(vouchertype.id, showdate.id).
    update_attributes!(:promo_code => promo)
end

Given /^the following walkup tickets have been sold for "(.*)":$/ do |dt, tickets|
  tickets.hashes.each do |t|
    qty = t[:qty].to_i
    steps %Q{Given #{t[:qty]} "#{t[:type]}" tickets have been sold for "#{dt}"}
  end
end

Given /^(\d+) "(.*)" tickets? have been sold for "(.*)"$/ do |qty,vtype,dt|
  order = build(:order, :walkup => true)
  qty = qty.to_i
  showdate = Showdate.find_by_thedate!(Time.zone.parse(dt))
  offer = ValidVoucher.find_by_vouchertype_id_and_showdate_id!(
    Vouchertype.find_by_name!(vtype).id,
    showdate.id)
  order.add_tickets(offer, qty)
  order.finalize!
end

Then /^I should see "(.*)" within the container for "(.*)" tickets$/ do |message, name|
  div_id = Vouchertype.find_by_name!(name).id
  page.find("div#vouchertype_#{div_id} span.admin").text.should == message
end

When /^I try to redeem the "(.*)" discount code$/ do |promo|
  # should really use headless JS for this
  visit store_path(:promo_code => promo)
end

When /^I fill in the "(.*)" fields with "(\S+)\s+(\S+),\s*([^,]+),\s*([^,]+),\s*(\S+)\s+(\S+),\s*([^,]+),\s*(.*@.*)"$/ do |fieldset, first, last, street, city, state, zip, phone, email|
  with_scope "fieldset#{fieldset}" do
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

When /^I try to checkout as guest using "(.*)"$/ do |info|
  steps %Q{
  When I follow "Checkout as Guest"
  And I fill in the ".billing_info" fields with "#{info}"
}
end

When /^I successfully complete guest checkout$/ do
  steps %Q{
When I press "CONTINUE >>"
And I place my order with a valid credit card
}
end

Then /^the gift recipient customer should be "(.*)\s+(.*)"$/ do |first,last|
  verify_customer_in_div "#gift_recipient", first, last
end

Then /^the billing customer should be "(.*)\s+(.*)"$/ do |first,last|
  within('#purchaser') { page.should have_content("#{first} #{last}") }
end

