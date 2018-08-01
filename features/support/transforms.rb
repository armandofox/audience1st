Transform /^\s-*\d\d\d\d-\d\d-\d\d\s-*$/ do |date|
  Time.zone.parse date
end
