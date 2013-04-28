def process_tickets(hashes)
  hashes.each do |t|
    show,qty,type,price,showdate = t.values_at(:show, :qty, :type,:price,:showdate)
    Given %Q{a show "#{show}" with #{10+qty.to_i} "#{type}" tickets for $#{price} on "#{showdate}"}
    visit path_to %Q{the store page for "#{show}"}
    select show, :from => 'Show'
    select_date_matching showdate, :from => 'Date'
    select qty, :from => "#{type} - $#{price}"
  end
end

Given /^a show "(.*)" with "(.*)" tickets for \$?(.*) on "(.*)"$/ do |show,type,price,date|
  Given %Q{a show "#{show}" with 100 "#{type}" tickets for $#{price} on "#{date}"}
end

Given /^a show "(.*)" with (\d+) "(.*)" tickets for \$(.*) on "(.*)"$/ do |show,num,type,price,date|
  Given %Q{a performance of "#{show}" on "#{date}"}
  Given %Q{#{num} #{type} vouchers costing $#{price} are available for that performance}
end

Given /^a show "(.*)" with the following tickets available:$/ do |show_name, tickets|
  tickets.hashes.each do |t|
    Given %Q{a show "#{show_name}" with #{t[:qty]} "#{t[:type]}" tickets for #{t[:price]} on "#{t[:showdate]}"}
  end
end

Given /^my cart contains the following tickets:/ do |tickets|
  process_tickets(tickets.hashes)
  click_button 'CONTINUE >>'
end

Given /^my cart contains (\d+) "(.*)" bundle vouchers$/ do |qty,name|
  visit path_to(%Q{the subscriptions page})
  select qty.to_s, :from => name
  click_button 'CONTINUE >>'
end

Given /^my gift order contains the following tickets:/ do |tickets|
  Option.first.update_attributes!(:allow_gift_tickets => true, :allow_gift_subscriptions => true)
  process_tickets(tickets.hashes)
  check 'gift'
  click_button 'CONTINUE >>'
end

Given /^the following walkup tickets have been sold for "(.*)":$/ do |dt, tickets|
  showdate = Showdate.find_by_thedate!(Time.parse(dt))
  tickets.hashes.each do |t|
    qty = t[:qty].to_i
    offer = ValidVoucher.find_by_vouchertype_id_and_showdate_id!(
      Vouchertype.find_by_name!(t[:type]).id,
      showdate.id)
    vouchers = offer.sell!(qty, Customer.walkup_customer, Purchasemethod.find_by_shortdesc!(t[:payment]), Customer.boxoffice_daemon)
    vouchers.map { |v| v.walkup = true ; v.save! }
    vouchers.length.should == qty
  end
end

Then /^the cart should contain (\d+) "(.*)" tickets for "(.*)"$/ do |num, type, date_string|
  date_string = Time.parse(date_string).to_formatted_s(:showtime)
  Then %Q{I should see /#{date_string}.*?#{type}/ within "#cart_items" #{num} times}
end

Then /^the cart should not contain a donation$/ do
  Then %Q{I should not see "Donation" within "#cart_items"}
end

When /^the order is placed successfully$/ do
  click_button 'Charge Credit Card' # but will be handled as Cash sale in 'test' environment
end

Then /^the cart should contain a donation of \$(.*) to "(.*)"$/ do |amount,account|
  # This should really check internal state of the cart, but due to current poor design
  #  that state's not externally grabbable because it's buried in the session.
  Then %Q{I should see /#{sprintf('%.02f',amount)}.*?Donation to #{account}/ within "#cart_items" 1 times}
end

When /^I fill in the "(.*)" fields with "(\S+)\s+(\S+),\s*([^,]+),\s*([^,]+),\s*(\S+)\s+(\S+),\s*([^,]+),\s*(.*@.*)"$/ do |fieldset, first, last, street, city, state, zip, phone, email|
  with_scope "fieldset##{fieldset}" do
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

def verify_customer_in_div(id, first, last)
  with_scope id do
    find_field("customer[first_name]").value.should == first
    find_field("customer[last_name]").value.should == last
  end
end

Then /^the billing customer should be "(.*)\s+(.*)"$/ do |first,last|
  verify_customer_in_div "#billing", first, last
end

Then /^the gift recipient customer should be "(.*)\s+(.*)"$/ do |first,last|
  verify_customer_in_div "#gift_recipient", first, last
end
