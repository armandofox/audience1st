Given /^(?:my cart contains|I add) (\d+) "(.*)" (bundles|subscriptions)$/ do |qty,name,_|
  unless Vouchertype.where('name = ? AND category = ?', name, 'bundle').first
    steps "Given a \"#{name}\" subscription available to anyone for $50.00"
  end
  visit path_to(%Q{the subscriptions page})
  select qty.to_s, :from => name
  click_button 'CONTINUE >>', :disabled => true
end

Given /^(?:my cart contains|I add) the following tickets:/ do |tickets|
  create_tickets(tickets.hashes)
  click_button 'CONTINUE >>', :disabled => true
end

Given /^I add the following tickets for customer "(.*)":/ do |customer,tickets|
  create_tickets(tickets.hashes, customer)
  click_button 'CONTINUE >>', :disabled => true
end

Given /^my gift order contains the following tickets:/ do |tickets|
  Option.first.update_attributes!(:allow_gift_tickets => true, :allow_gift_subscriptions => true)
  create_tickets(tickets.hashes)
  check 'gift'
  click_button 'CONTINUE >>', :disabled => true
end

Then /^the cart should contain (\d+) "(.*)" (bundles|subscriptions)$/ do |num, type, what|
  steps %Q{Then I should see /#{type}/ within "#cart" #{num} times}
end

Then /^the cart should contain (\d+) "(.*)" tickets for "(.*)"$/ do |num, type, date_string|
  date_string = Time.zone.parse(date_string).to_formatted_s(:showtime)
  steps %Q{Then I should see /#{date_string}.*?#{type}/ within "#cart" #{num} times}
end


Then /^the cart should contain a donation of \$(.*) to "(.*)"$/ do |amount,account|
  steps %Q{Then I should see /Donation to #{account}.*?#{sprintf('%.02f',amount)}/ within "#cart" 1 times}
end

Then /^the cart should not contain a donation$/ do
  steps %Q{Then I should not see "Donation" within "#cart"}
end

Then /^the cart should show the following items:$/ do |table|
  table.hashes.each do |item|
    formatted_price = number_to_currency(item['price'].to_f)
    page.all('#cart .row').any? do |entry|
      (entry.find('.a1-cart-amount').has_content?(formatted_price) rescue  nil) &&
        entry.has_content?(item['description'])
    end
  end
end

Then /^the cart total price should be \$?([0-9.]+)$/ do |price|
  page.find('.a1-cart-total-amount').should have_content(number_to_currency price.to_f)
end
