Given /^(?:my cart contains|I add) (\d+) "(.*)" (bundles|subscriptions)$/ do |qty,name,_|
  unless Vouchertype.where('name = ? AND category = ?', name, 'bundle').first
    steps "Given a \"#{name}\" subscription available to anyone for $50.00"
  end
  visit path_to(%Q{the subscriptions page})
  select qty.to_s, :from => name
  click_button 'CONTINUE >>'
end

Then /^the cart should contain (\d+) "(.*)" (bundles|subscriptions)$/ do |num, type, what|
  steps %Q{Then I should see /#{type}/ within "#cart_items" #{num} times}
end

Given /^(?:my cart contains|I add) the following tickets:/ do |tickets|
  create_tickets(tickets.hashes)
  click_button 'CONTINUE >>'
end

Then /^the cart should contain (\d+) "(.*)" tickets for "(.*)"$/ do |num, type, date_string|
  date_string = Time.parse(date_string).to_formatted_s(:showtime)
  steps %Q{Then I should see /#{date_string}.*?#{type}/ within "#cart_items" #{num} times}
end


Then /^the cart should contain a donation of \$(.*) to "(.*)"$/ do |amount,account|
  # This should really check internal state of the cart, but due to current poor design
  #  that state's not externally grabbable because it's buried in the session.
  steps %Q{Then I should see /#{sprintf('%.02f',amount)}.*?Donation to #{account}/ within "#cart_items" 1 times}
end

Then /^the cart should not contain a donation$/ do
  steps %Q{Then I should not see "Donation" within "#cart_items"}
end

Then /^the cart should show the following items:$/ do |table|
  table.hashes.each do |item|
    formatted_price = number_to_currency(item['price'].to_f)
    page.all('li.cart_item').any? do |entry|
      entry.find('.cart_item_price').has_content?(formatted_price) &&
        entry.find('.cart_item_desc').has_content?(item['description'])
    end
  end
end

Then /^the cart total price should be \$?([0-9.]+)$/ do |price|
  within '#cart_total' do ; page.should have_content(number_to_currency price.to_f) ; end
end
