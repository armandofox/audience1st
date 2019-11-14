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
