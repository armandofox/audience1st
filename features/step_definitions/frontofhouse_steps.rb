When /I complete the walkup sale with cash/ do
  choose('Cash or Zero-Revenue')
  click_button 'submit_cash'
  expect(page.find(:css, '#notices').text).to match( /tickets \(total[^\)]+\) paid/ )
end

When /I complete the walkup sale with credit card/ do
  steps %Q{
When I fill in a valid credit card for "John Doe"
And I press "Charge Credit Card"
}
  end


Then /customer "(.*) (.*)" should be checked in for (\d+) seats? on (.*)$/ do |first,last,seats,date|
  showdate = Showdate.where(:thedate => Time.zone.parse(date)).first
  customer = find_or_create_customer first,last
  seats = seats.to_i
  expect(customer.vouchers.where(:showdate => showdate, :checked_in => true).size).to eq(seats)
end

Then /^I should see the following details in door list:$/ do |table|
    table.hashes.each do |h|
      page.should have_content h[:content]
    end
end
