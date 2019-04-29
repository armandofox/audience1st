require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

World(ModelAccess)

# Element should be disabled
Then /^the "(.*)" (?:checkbox|button|field|control) should be disabled/ do |field|
  expect(page).to have_field(field, :disabled => true)
end

# Field should have value
Then /^the "(.*)" field should be "(.*)"$/ do |field,val|
  page.should have_field(field, :with => val)
end
# Check for a JavaScript alert (when running with a JS-aware Capybara driver)

Then /^I should see an alert matching \/(.*)\/$/ do |regex|
  # Rails3 - the following should work with more recent Capybara
  expect(accept_alert()).to match(Regexp.new regex)
end

# Check for N occurrences of something
Then /^(?:|I )should see \/([^\/]*?)\/ (within "(.*?)" )?(\d+) times$/ do |regexp, _, selector, count|
  regexp = Regexp.new(regexp, Regexp::MULTILINE)
  count = count.to_i
  if selector
    within(selector) { page.find(:xpath, '/*').text.split(regexp).length.should == 1+count }
  else
    page.find(:xpath, '/*').text.split(regexp).length.should == 1+count
  end
end

# Wrapper around 'I should see ... within ...' steps
Then /^I should see ([\"\/].*[\"\/]) within the "(.*)" (.*)$/ do |string,tag,id|
  steps %Q{Then I should see #{string} within "#{tag}[@id='#{id}']"}
end
Then /^I should not see ([\"\/].*[\"\/]) within the "(.*)" (.*)$/ do |string,tag,id|
  steps %Q{Then I should not see #{string} within "#{tag}[@id='#{id}']"}
end

# Check if menu option selected
Then /^"(.*)" should be selected in the "(.*)" menu$/ do |opt,menu|
  html = Nokogiri::HTML(page.body)
  menu_id = if !html.xpath("//select[@id='#{menu}']").empty? then menu else html.xpath("//label[contains(text(),'#{menu}')]").first['for'] end
  html.xpath("//select[@id='#{menu_id}']/option[contains(text(),'#{opt}')]").first['selected'].should_not be_blank, "Expected '#{opt}' to be selected in the '#{menu}' menu, but it was not"
end

Then /^nothing should be selected in the "(.*)" menu$/ do |menu|
  html = Nokogiri::HTML(page.body)
  menu_id = if !html.xpath("//select[@id='#{menu}']").empty? then menu else html.xpath("//label[contains(text(),'#{menu}')]").first['for'] end
  within "##{menu_id}" do
    # there should exist a blank option
    page.should have_xpath("//option[contains(text(),'')]"), "Menu doesn't have a blank option"
    # no nonblank option should be marked as 'selected'
    page.should have_no_xpath("//option[text() != '' and @selected='selected']"), "Expected menu's blank option to be selected, but it was not"
  end
end

# Select from menu using a regexp instead of exact string match
When /^I select \/([^\/]+)\/ from "(.*)"$/ do |rxp, field|
  select(Regexp.new(rxp), :from => field)
end

# 'I should see' within divs corresponding to named entities
Then /^(?:|I )should see "([^\"]*)" within the (.*) for(?: the) (.*) with (.*) "(.*)"$/ do |text,tag_type,entity_type,attribute,value|
  entity = get_model_instance(entity_type, attribute, value)
  selector_id = "#{entity_type}_#{entity.id}"
  steps %Q{Then I should see "#{text}" within "#{tag_type}\##{selector_id}"}
end

# 'should come before/should come after' for verifying orderings of things
Then /^(.*):"(.*)" should come (before|after) (.*):"(.*)" within "(.*)"$/ do |tag1,val1,order,tag2,val2,sel|
  html = Nokogiri::HTML(page.body)
  elt1 = html.xpath("//#{sel}//#{tag1}[contains(.,'#{val1}')]").first
  elt2 = html.xpath("//#{sel}//#{tag2}[contains(.,'#{val2}')]").first
  sequence = (elt1 <=> elt2)
  if order =~ /before/
    sequence.should == -1
  else
    sequence.should == 1
  end
end

# A dropdown menu of quantities associated with a particular voucher type.
# Capture the vouchertype label so we can refer to it later.

Then /^I should see a quantity menu for "([^\"]*)"$/ do |name|
  vtype = Vouchertype.find_by_name(name)
  page.should have_css("select.itemQty[name='vouchertype[#{vtype.id}]']")
end

Then /^the "([^\"]*)" menu should contain "([^\"]*)"$/ do |menu,choice|
  page.should(have_css("select[id=#{menu}]") || have_css("select[name=#{menu}]")) do |m|
    m.should have_css("option", :content => choice)
  end
end

Then /^I should see the "(.*)" message$/ do |m|
  page.should(have_css("div##{m}") || have_css("div.#{m}"))
end

# File uploading
When /^I upload (.*) import list "(.*)"$/ do |type,file|
  case type
  when /customer/i
    path = "customer_list"
  when /brown/i
    path = "brownpapertickets"
  when /goldstar/i
    path = "email_goldstar"
  else
    raise "Unknown import type #{type}; try 'customer list', 'Brown Paper Tickets', or 'Goldstar'"
  end
  attach_file :import_uploaded_data, File.join(Rails.root, 'spec', 'import_test_files', path, file)
  click_button "Preview Import"
end

# Fill in all fields in a fieldset
When /^I fill in the "(.*)" fields as follows:$/ do |fieldset, table|
  table.hashes.each do |t|
    case t[:value]
    when /^select date "(.*)"$/
      steps %Q{When I select "#{$1}" as the "#{t[:field]}" date}
    when /^select "(.*)"$/
      steps %Q{When I select "#{$1}" from "#{t[:field]}"}
    when /^(un)?checked$/
      steps %Q{When I #{$1}check "#{t[:field]}"}
    else
      steps %Q{When I fill in "#{t[:field]}" with "#{t[:value]}"}
    end
  end
end

# Lets you write step def such as:
# Then I should see the message for "customers.confirm_delete"
Then /I should see the message for "(.*)"/ do |i18n_key| 
  message = I18n.translate!(i18n_key)
  page.should have_content(message)
end
