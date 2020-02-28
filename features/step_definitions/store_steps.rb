module ScenarioHelpers
  module CustomerDivs
    def verify_customer_in_div(id, first, last)
      with_scope id do
        find_field("customer[first_name]").value.should == first
        find_field("customer[last_name]").value.should == last
      end
    end
  end
end
World(ScenarioHelpers::CustomerDivs)

# Preparing to put things in the cart

When /^I try to redeem the "(.*)" discount code$/ do |promo|
  # should really use headless JS for this
  visit store_path(:promo_code => promo)
end

Then /^I should see "(.*)" within the container for "(.*)" tickets$/ do |message, name|
  div_id = Vouchertype.find_by_name!(name).id
  page.find("div#vouchertype_#{div_id} .s-explain").text.should == message
end


# Adding things to a store order

Given /^(?:my cart contains|I add) (\d+) "(.*)" (bundles|subscriptions)$/ do |qty,name,_|
  unless Vouchertype.where('name = ? AND category = ?', name, 'bundle').first
    steps "Given a \"#{name}\" subscription available to anyone for $50.00"
  end
  visit path_to(%Q{the subscriptions page})
  select qty.to_s, :from => name
  find('input#submit').click
end

Given /^(?:my cart contains|I add) the following tickets:/ do |tickets|
  create_tickets(tickets.hashes)
  find('input#submit').click
end

Given /^I add the following tickets for customer "(.*)":/ do |customer,tickets|
  create_tickets(tickets.hashes, customer)
  find('input#submit').click
end

Given /^my gift order contains the following tickets:/ do |tickets|
  Option.first.update_attributes!(:allow_gift_tickets => true, :allow_gift_subscriptions => true)
  create_tickets(tickets.hashes)
  check 'gift'
  find('input#submit').click
end

# Cart should contain items

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
  order_rows = page.all('#cart .order-row')
  table.hashes.each do |item|
    found_match = order_rows.any? do |entry|
      seats_match = item['seats'].blank? ||  (entry.has_content?('Seat') && entry.has_content?(item['seats']))
      price_matches =
        entry.find('.a1-cart-amount').has_content?(number_to_currency(item['price'].to_f),
        :normalize_ws => true) 
      description_matches = entry.has_content?(item['description'], :normalize_ws => true)
      description_matches && price_matches && seats_match
    end
    expect(found_match).to be_truthy
  end
end

Then /^the cart total price should be \$?([0-9.]+)$/ do |price|
  page.find('.a1-cart-total-amount').should have_content(number_to_currency price.to_f)
end

