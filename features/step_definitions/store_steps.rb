Given /^a show "(.*)" with "(.*)" tickets for \$?(.*) on "(.*)"$/ do |show,type,price,date|
  steps %Q{Given a show "#{show}" with 100 "#{type}" tickets for $#{price} on "#{date}"}
end

Given /^a show "(.*)" with (\d+) "(.*)" tickets for \$(.*) on "(.*)"$/ do |show,num,type,price,date|
  steps %Q{Given a performance of "#{show}" on "#{date}"
           And #{num} #{type} vouchers costing $#{price} are available for that performance}
end

Given /^a show "(.*)" with the following tickets available:$/ do |show_name, tickets|
  tickets.hashes.each do |t|
    steps %Q{Given a show "#{show_name}" with #{t[:qty]} "#{t[:type]}" tickets for #{t[:price]} on "#{t[:showdate]}"}
  end
end

Given /^my gift order contains the following tickets:/ do |tickets|
  Option.first.update_attributes!(:allow_gift_tickets => true, :allow_gift_subscriptions => true)
  create_tickets(tickets.hashes)
  check 'gift'
  click_button 'CONTINUE >>'
end

Given /^the following walkup tickets have been sold for "(.*)":$/ do |dt, tickets|
  order = BasicModels.create_empty_walkup_order
  showdate = Showdate.find_by_thedate!(Time.parse(dt))
  tickets.hashes.each do |t|
    qty = t[:qty].to_i
    offer = ValidVoucher.find_by_vouchertype_id_and_showdate_id!(
      Vouchertype.find_by_name!(t[:type]).id,
      showdate.id)
    order.add_tickets(offer, qty)
  end
  order.finalize!
end

Then /^I should see "(.*)" within the container for "(.*)" tickets$/ do |message, name|
  div_id = Vouchertype.find_by_name!(name).id
  page.find("div#vouchertype_#{div_id} span.admin").text.should == message
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
