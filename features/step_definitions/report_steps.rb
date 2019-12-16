# Unfulfilled orders

When /I mark orders (.*) as fulfilled/ do |row_numbers|
  row_numbers.split(/\s*,\s*/).each do |id|
    check "voucher_#{id}"
  end
  click_button "Mark Checked Orders as Fulfilled"
end

# Revenue by payment type and account code report

When /I view revenue by payment type from "(.*)" to "(.*)"$/ do |from,to|
  steps %Q{
When I visit the reports page
And I select "#{from} to #{to}" as the "txn_report_dates" date range
And I press "Display on Screen" within "#financial_reports"
}
end

Then /the "(.*)" subtotals should be exactly:/ do |pmt_type, tbl|
  tbl.hashes.each do |acc_code|
    ac = AccountCode.find_by!(:code => acc_code['account_code']).id
    subtotal = acc_code['total'].to_f
    if subtotal.zero?           # there should not be a subtotal row for this
      expect(page).not_to have_css("#subtotal_#{pmt_type}_#{ac}")
    else
      expect(page.find(:css, "#subtotal_#{pmt_type}_#{ac}").text).
        to eq("$#{acc_code['total']}")
    end
  end
end

# Customer lists

Then /the report output should include only customers: (.*)/ do |arg|
  num_matches = arg.split(/\s*,\s*/).size
  if num_matches.zero?
    choose 'Estimate number of matches'
    click_button 'Run Report'
    expect(accept_alert()).to match(/0 matches/)
  else
    choose 'Display list on screen'
    click_button 'Run Report'
    steps %Q{Then column "First name" of table "#customers" should include only: #{arg}}
  end
end

When /^I run the special report "All subscribers" with seasons: (.*)/ do |seasons|
  visit path_to "the reports page"
  select "All subscribers", :from => 'special_report_name'
    within '#report_body' do
    unselect Time.this_season.to_s, :from => 'seasons'
    seasons.split(/\s*,\s*/).each do |season|
      select season, :from => 'seasons'
    end
  end
end

When /^I run the special report "All subscribers" with vouchertypes: (.*)/ do |vouchertypes|
  visit path_to "the reports page"
  select "All subscribers", :from => 'special_report_name'
    within '#report_body' do
      vouchertypes.split(/\s*,\s*/).each do |vouchertype|
      select vouchertype, :from => 'vouchertypes'
    end
  end
end

When /^I run the special report "Lapsed subscribers" to find (.*) subscribers who have not renewed in (.*)$/ do |old,new|
  visit path_to "the reports page"
  select "Lapsed subscribers", :from => 'special_report_name'
  within '#report_body' do
    old.split(/\s*,\s*/).each { |s| select s, :from => 'have_vouchertypes' }
    new.split(/\s*,\s*/).each { |s| select s, :from => 'dont_have_vouchertypes' }
  end
end
  

When /^I fill in the special report "(.*)" with:$/ do |report_name, fields|
  visit path_to "the reports page"
  select report_name, :from => 'special_report_name'
    within '#report_body' do
    fields.hashes.each do |form_field|
      case form_field[:action]
      when /select/
        select form_field[:value], :from => form_field[:field_name]
      when /check/
        check form_field[:field_name]
      else
        raise "Unknown action #{form_field[:action]}"
      end
    end
  end
end

# Check contents of downloaded report export

Then /a CSV file should be downloaded containing:/ do |tbl|
  header = page.response_headers['Content-Disposition']
  expect(header).to match /^attachment/
  expect(header).to match /filename=".*\.csv"$/
  expected_rows = page.body.split(/\n/).map(&:strip)
  tbl.raw.each_with_index do |row,ndx|
    expect(expected_rows[ndx]).to eq row.join(',').sub(/,+$/, '')
  end
end
