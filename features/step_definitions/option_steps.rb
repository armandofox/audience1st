 Given /the season start date is (.*)$/ do |date|
   d = Date.parse(date)
   Option.first.update_attributes!(:season_start_month => d.month, :season_start_day => d.day)
 end

 When /^I fill in all valid options$/ do
   opts = {
     'venue' => "Test Theater",
     'advance_sales_cutoff' => "60",
     'nearly_sold_out_threshold' => "80",
     'cancel_grace_period' => "1440",
     'send_birthday_reminders' => "0",
     'terms_of_sale' => 'Sales Final',
     'precheckout_popup' => 'Please double check dates',
     'venue_homepage_url' => 'http://test.org'
   }
   opts.each_pair do |opt,val|
     fill_in "option[#{opt}]", :with => val
   end
 end

 Given /^the (boolean )?setting "(.*)" is "(.*)"$/ do |bool,opt,val|
   val = !!(val =~ /true/i) if bool
   Option.first.update_attributes!(opt.downcase.gsub(/\s+/, '_') => val)
 end

 When /I upload the email template "(.*)"/ do |filename|
   within '#edit_options_form' do
     attach_file 'html_email_template', "#{TEST_FILES_DIR}/email/#{filename}", :visible => false
     click_button 'Update Settings'
   end
 end

 Then /^the setting "(.*)" should be "(.*)"$/ do |opt,val|
   expect(Option.send(opt.tr(' ','').underscore)).to eq(val)
 end

 #####
 # Step defintions for testing the recurring donation feature admin view
 #####
 When /I set allow recurring donations to "(.*)"/ do |value|
  drop_down = page.find(:css, "#allow_recurring_donations_select")
  drop_down.select(value)
 end
 Then /the radio button to select the default donation type should be "(.*)"/ do |value|
  if value == 'visible'
    expect(page).to have_selector('#default_donation_type_form_row', visible: value)
  elsif value == 'hidden'
    expect(page).not_to have_selector('#default_donation_type_form_row')
  end
 end

 ######
 # Step defintions for testing the recurring donation feature user view
 ######

 Given /admin (has|has not) allowed recurring donations/ do |value|
   if value == 'has'
     value = true
   elsif value == 'has not'
     value = false
   end
   Option.first.update_attributes!(:allow_recurring_donations => value)
  end
  When /I select monthly in the donation frequency radio button/ do
   radio_button = page.find(:css, "#donation_frequency_radio")
   radio_button.choose("Monthly")
  end
  Then /there should be a Recurring Donation record belonging to "(.*) (.*)"$/ do |first,last|
   r = RecurringDonation.first
   c = Customer.find(r.customer_id)
   expect(c.first_name).to eq(first)
   expect(c.last_name).to eq(last)
  end
  Then /there should be a regular Donation record belonging to "(.*) (.*)"$/ do |first,last|
    r = RecurringDonation.first
    expect(r.donations.count).to eq(1)
    d = r.donations[0]
    expect(Donation.count).to eq(1)
    expect(d).to eq(Donation.first)
    c = Customer.find(d.customer_id)
    expect(c.first_name).to eq(first)
    expect(c.last_name).to eq(last)
  end 
  Then /a Recurring Donation record should not be created$/ do
    expect(RecurringDonation.first).to eq(nil)
  end
  Then /a regular Donation record should not be created$/ do
    expect(Donation.first).to eq(nil)
  end
