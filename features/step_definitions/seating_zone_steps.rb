Then /seating zone "(.*) \((.*)\)" with display order (\d+) should exist/ do |name,short,ord|
  @seating_zone = SeatingZone.find_by(:name => name)
  expect(@seating_zone.short_name).to eq short
  expect(@seating_zone.display_order).to eq ord
end
