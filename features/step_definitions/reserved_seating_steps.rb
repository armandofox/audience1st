Given /the "(.*)" performance has reserved seating/ do |datetime|
  @showdate = Showdate.find_by!(:thedate => Time.zone.parse(datetime))
  steps %Q{Given that performance has reserved seating}
end

Given /that performance has reserved seating/ do
  @seatmap = create(:seatmap)
  @showdate.seatmap = @seatmap
  @showdate.max_advance_sales = [@showdate.max_advance_sales, @seatmap.seat_count].min
  @showdate.save!
end

Given /^the following seat reservations for the (.*) performance:$/ do |time,tbl|
  @showdate ||= create(:reserved_seating_showdate, :date => Time.zone.parse(time))
  tbl.hashes.each do |h|
    customer = find_or_create_customer h['first'], h['last']
    vouchertype = Vouchertype.find_by(:name => h['vouchertype']) || create(:revenue_vouchertype, :name => h['vouchertype'])
    seats = h['seats'].split(/\s*,\s*/)
    buy!(customer, vouchertype, seats.length, showdate: @showdate, seats: seats)
  end
end

When /I successfully choose seats? (.*)/ do |seats|
  steps %Q{
When I press "Choose Seats..."
Then I should see the seatmap
When I choose seats #{seats}
}
end

Then /I should (not )?see the seatmap/ do |no|
  if no
    expect(page).not_to have_selector('#seating-charts-wrapper', :visible => true)
  else
    expect(page).to have_selector('#seating-charts-wrapper', :visible => true)
  end
end

When /I choose seats (.*)/ do |seat_list|
  seat_list.split(/\s*,\s*/).each do |seat|
    page.find("##{seat}").click
  end
end

Then /I should see "(.*)" in the list of selected seats/ do |seat_list|
  selected_seats = page.find('.seat-display').value.split(/\s*,\s*/)
  seat_list.split(/\s*,\s*/).each do |seat|
    expect(selected_seats).to include(seat)
  end
end

Then /seats (.*) should be (occupied|available) for the (.*) performance/ do |seats,avail,thedate|
  @showdate = Showdate.find_by(:thedate => Time.zone.parse(thedate))
  @seats = seats.split(/\s*,\s*/)
  occupied = @showdate.occupied_seats & @seats
  if avail =~ /available/
    expect(occupied).to be_empty
  else
    expect(occupied).to eq(@seats)
  end
end
