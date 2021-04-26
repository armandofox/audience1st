require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require 'webmock/cucumber'

World(ModelAccess)

# Non-existence of a field type
Then /I should not see a (.*) named "(.*)"/ do |elt, selector|
  case elt
  when 'menu'
    expect(page).not_to have_select(selector)
  else
    raise "Don't know how to check for absence of '#{elt}'"
  end
end

# Element should be disabled
Then /^the "(.*)" (?:checkbox|button|field|control) should be (enabled|disabled)/ do |field,able|
  expect(page).to have_field(field, :disabled => (able == 'disabled'))
end

# Field should have value
Then /^the "(.*)" field should be "(.*)"$/ do |field,val|
  page.should have_field(field, :with => val)
end


# Check for N occurrences of something
Then /^(?:|I )should see \/([^\/]*?)\/ (within "(.*?)" )?(\d+) times$/ do |regexp, selector, count|
  regexp = Regexp.new(regexp, Regexp::MULTILINE)
  count = count.to_i
  if selector
    within(selector) { page.find(:xpath, '/*').text.split(regexp).length.should == 1+count }
  else
    page.find(:xpath, '/*').text.split(regexp).length.should == 1+count
  end
end

# Check for a JavaScript alert (when running with a JS-aware Capybara driver)

Then /^I should see an alert matching \/(.*)\/$/ do |regex|
  # Rails3 - the following should work with more recent Capybara
  expect(accept_alert()).to match(Regexp.new regex)
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

# Check if menu does or does not contain an option
Then /the "(.*)" menu should have options: (.*)/ do |menu,option|
  options = option.split(/\s*;\s*/)
  expect(page).to have_select(menu, :options => options)
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

# Fill in all fields in a fieldset
When /^I fill in the "(.*)" fields as follows:$/ do |fieldset, table|
  table.hashes.each do |t|
    attr,val = t[:field],t[:value]
    case val
    when /^date range "(.*)" to "(.*)"$/
      steps %Q{When I select "#{$1} to #{$2}" as the "#{attr}" date range}
    when /^select time "(.*)"/
      steps %Q{When I select "#{$1}" as the "#{attr}" time}
    when /^select date "(.*)"$/
      steps %Q{When I select "#{$1}" as the "#{attr}" date}
    when /^select "(.*)"$/
      steps %Q{When I select "#{$1}" from "#{attr}"}
    when /^(un)?checked$/
      steps %Q{When I #{$1}check "#{attr}"}
    else
      steps %Q{When I fill in "#{attr}" with "#{val}"}
    end
  end
end

# Lets you write step def such as:
# Then I should see the message for "customers.confirm_delete"
Then /I should (not )?see the message for "(.*)"/ do |no,i18n_key| 
  message = I18n.translate!(i18n_key)
  if no
    expect(page).not_to have_content(message)
  else
    expect(page).to have_content(message)
  end
end

# Selectively allow successful and unsuccessful external requests
Given /the URI "(.*)" is (not )?readable/ do |uri,no|
  uri.gsub!(/^https?:\/\//, '')
  if no
    stub_request(:any, uri).to_return(:status => [400, 'Bad request'])
  else
    stub_request(:any, uri).to_return(:headers => {})
  end
end

When /^I enable the reminder email feature$/ do
  enable_new_feature('reminder_emails')
end
