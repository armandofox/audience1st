Then /customer "(.*) (.*)" should be checked in for (\d+) seats? on (.*)$/ do |first,last,seats,date|
  showdate = Showdate.where(:thedate => Time.parse(date)).first
  customer = find_or_create_customer first,last
  seats = seats.to_i
  expect(customer.vouchers.where(:showdate => showdate, :checked_in => true).size).to eq(seats)
end

