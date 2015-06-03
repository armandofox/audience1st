 Given /the season start date is (.*)$/ do |date|
   d = Date.parse(date)
   Option.first.update_attributes!(:season_start_month => d.month, :season_start_day => d.day)
 end
 
 Given /^I fill in all valid options$/ do
   opts = {
     'venue' => "Test Theater",
     'advance_sales_cutoff' => "60",
     'sold_out_threshold' => "90",
     'nearly_sold_out_threshold' => "80",
     'cancel_grace_period' => "1440",
     'venue' => "Test Theater",
     'send_birthday_reminders' => "0",
     'followup_visit_reminder_lead_time' => "0",
     'terms_of_sale' => 'Sales Final',
     'subscription_order_service_charge' => '3',
     'subscription_service_charge_description' => 'Service Charge',
     'precheckout_popup' => 'Please double check dates',
     'venue_homepage_url' => 'http://test.org'
   }
   opts.each_pair do |opt,val|
     fill_in "option[#{opt}]", :with => val
   end
 end
 
 Given /^the setting "(.*)" is "(.*)"$/ do |opt,val|
   Option.first.update_attributes!(opt.downcase.gsub(/\s+/, '_') => val)
 end
 
