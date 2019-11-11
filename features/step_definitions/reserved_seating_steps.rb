Then /I should (not )?see the seatmap/ do |no|
  if no
    expect(page).not_to have_selector('#seating-charts-wrapper', :visible => true)
  else
    expect(page).to have_selector('#seating-charts-wrapper', :visible => true)
  end
end


