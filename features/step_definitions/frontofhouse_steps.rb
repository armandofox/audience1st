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

Then /^I should not see the following details in door list:$/ do |table|
  table.hashes.each do |h|
    page.should have_content h[:content]
  end
end
