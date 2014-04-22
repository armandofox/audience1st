Given /^my cart contains (\d+) "(.*)" bundle vouchers$/ do |qty,name|
  visit path_to(%Q{the subscriptions page})
  select qty.to_s, :from => name
  click_button 'CONTINUE >>'
end


Given /^my cart contains the following tickets:/ do |tickets|
  create_tickets(tickets.hashes)
  click_button 'CONTINUE >>'
end

Then /^the cart should contain (\d+) "(.*)" tickets for "(.*)"$/ do |num, type, date_string|
  date_string = Time.parse(date_string).to_formatted_s(:showtime)
  Then %Q{I should see /#{date_string}.*?#{type}/ within "#cart_items" #{num} times}
end

Then /^the cart should contain (\d+) "(.*)" (bundles|subscriptions)$/ do |num, type, what|
  Then %Q{I should see /#{type}/ within "#cart_items" #{num} times}
end


Then /^the cart should contain a donation of \$(.*) to "(.*)"$/ do |amount,account|
  # This should really check internal state of the cart, but due to current poor design
  #  that state's not externally grabbable because it's buried in the session.
  Then %Q{I should see /#{sprintf('%.02f',amount)}.*?Donation to #{account}/ within "#cart_items" 1 times}
end

Then /^the cart should not contain a donation$/ do
  Then %Q{I should not see "Donation" within "#cart_items"}
end

