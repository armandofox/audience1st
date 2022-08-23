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
When I choose seats "#{seats}"
}
end

Then /I should (not )?see the seatmap/ do |no|
  if no
    expect(page).not_to have_selector('#seating-charts-wrapper', :visible => true)
  else
    expect(page).to have_selector('#seating-charts-wrapper', :visible => true)
  end
end

When /I choose seats? "([^"]+)"(?: for import customer "(.*)")?/ do |seat_list, name|
  if name
    within(find_import_row_for name) { find('.select-seats').click }
    steps %Q{Then I should see the seatmap}
  end
  seat_list.split(/\s*,\s*/).each do |seat|
    page.find("##{seat}").click
  end
  sleep 2
end

When /I (fail to )?confirm seats? "(.*)" for import customer "(.*)"/ do |should_fail, seat_list, name|
  if should_fail
    # this is messy: all we can really do is force assign_seat to fail for ANY voucher
    # so scenarios that use this step cannot subsequently expect a different seat
    # assignment confirmation to fail.
    allow_any_instance_of(Voucher).to receive(:assign_seat).and_return(nil)
  end
  steps %Q{When I choose seats "#{seat_list}" for import customer "#{name}"}
  within(find_import_row_for name) { click_button "Confirm" }
end

Then /import customer "(.*)" should not have any seat assignment/ do |name|
  within(find_import_row_for name) { expect(find('.seat-display').value).to be_blank }
end

Then /import customer "(.*)" should have seats (.*)/ do |name,seats|
  within(find_import_row_for name) { expect(find('.seat-display').value.gsub(/\s+/,'')).to eq(seats) }
end

Then /I should see "(.*)" in the list of selected seats/ do |seat_list|
  selected_seats = page.find('.seat-display').value.split(/\s*,\s*/)
  seat_list.split(/\s*,\s*/).each do |seat|
    expect(selected_seats).to include(seat)
  end
end

Then /seats (.*) should be (occupied|available) for the (.*) performance/ do |seats,avail,thedate|
  @showdate = Showdate.find_by!(:thedate => Time.zone.parse(thedate))
  @seats = seats.split(/\s*,\s*/)
  occupied = @showdate.occupied_seats & @seats
  if avail =~ /available/
    expect(occupied).to be_empty
  else
    expect(occupied).to eq(@seats)
  end
end

Then /the (.*) performance should have the following seat assignments:/ do |showdate,list|
  list.hashes.each do |v|
    steps %Q{Then customer "#{v['name']}" should have seats #{v['seats']} for the #{showdate} performance}
  end
end
