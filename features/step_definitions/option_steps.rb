 Given /the season start date is (.*)$/ do |date|
   d = Date.parse(date)
   Option.set_value!(:season_start_month, d.month)
   Option.set_value!(:season_start_day, d.day)
 end
   
