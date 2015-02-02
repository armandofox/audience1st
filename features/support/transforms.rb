Transform /^\s-*\d\d\d\d-\d\d-\d\d\s-*$/ do |date|
  Time.parse date
end
