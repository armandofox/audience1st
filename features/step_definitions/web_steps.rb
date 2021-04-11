# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a 
# newer version of cucumber-rails. Consider adding your own code to a new file 
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.


require 'uri'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(locator) { yield } : yield
  end
end
World(WithinHelpers)

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )visit (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )press "([^\"]*)"(?: within "([^\"]*)")?$/ do |button, selector|
  with_scope(selector) do
    begin
      click_button(button)
    rescue Capybara::ElementNotFound
      click_button(button, :disabled => true)
    end
  end
end

When /^(?:|I )follow "([^\"]*)"(?: within "([^\"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

When /^(?:|I )fill in "([^\"]*)" with "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, value, selector|
  with_scope(selector) do
    fill_in(field, :with => value)
  end
end

When /^(?:|I )fill in "([^\"]*)" for "([^\"]*)"(?: within "([^\"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    fill_in(field, :with => value)
  end
end

# Use this to fill in an entire form with data from a table. Example:
#
#   When I fill in the following:
#     | Account Number | 5002       |
#     | Expiry date    | 2009-11-01 |
#     | Note           | Nice guy   |
#     | Wants Email?   |            |
#
# TODO: Add support for checkbox, select og option
# based on naming conventions.
#
When /^(?:|I )fill in the following(?: within "([^\"]*)")?:$/ do |selector, fields|
  with_scope(selector) do
    fields.rows_hash.each do |name, value|
      steps %Q{When I fill in "#{name}" with "#{value}"}
    end
  end
end

When /^(?:|I )select "([^\"]*)" from "([^\"]*)"(?: within "([^\"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    select(value, :from => field, :disabled => false)
  end
end

When /^(?:|I )check "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    check(field)
  end
end

When /^(?:|I )uncheck "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    uncheck(field)
  end
end

When /^(?:|I )choose "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    choose(field)
  end
end

When /^(?:|I )attach the file "([^\"]*)" to "([^\"]*)"(?: within "([^\"]*)")?$/ do |path, field, selector|
  with_scope(selector) do
    attach_file(field, path)
  end
end

Then /^(?:|I )should see "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, selector|
  with_scope(selector) do
    expect(page).to have_content(text, :normalize_ws => true)
  end
end

Then /^(?:|I )should see \/([^\/]*)\/(?: within "([^\"]*)")?$/ do |regexp, selector|
  regexp = Regexp.new(regexp)
  with_scope(selector) do
    expect(page).to have_xpath('//*', :text => regexp)
  end
end

Then /^(?:|I )should not see "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, selector|
  with_scope(selector) do
    expect(page).to have_no_content(text)
  end
end

Then /^(?:|I )should not see \/([^\/]*)\/(?: within "([^\"]*)")?$/ do |regexp, selector|
  regexp = Regexp.new(regexp)
  with_scope(selector) do
    expect(page).to have_no_xpath('//*', :text => regexp)
  end
end

# Created test
Then /^(?:|I )should (not )?see the following: "([^\"]*)"$/ do |no,textlist|
  textlist.split(/\s*,\s*/).each do |text|
    step "I should #{no}see \"#{text}\""
  end
end

Then /^the "([^\"]*)" field(?: within "([^\"]*)")? should (contain|equal) "([^\"]*)"$/ do |field, selector, equality_check, value|
  with_scope(selector) do
    val = find_field(field, :disabled => :all).value
    if equality_check =~ /equal/
      expect(val).to eq(value)
    else
      expect(val).to match(/#{value}/)
    end
  end
end

Then /^the "([^\"]*)" field(?: within "([^\"]*)")? should not (contain|equal) "([^\"]*)"$/ do |field, selector, equality_check, value|
  with_scope(selector) do
    val = find_field(field).value
    if equality_check =~ /equal/
      expect(val).to_not eq(value)
    else
      expect(val).to_not match(/#{value}/)
    end
  end
end

Then /^the "([^\"]*)" field(?: within "([^\"]*)")? should be blank$/ do |field, selector|
  with_scope(selector) do
    expect(find_field(field).value).to be_blank
  end
end

Then /^the "([^\"]*)" field(?: within "([^\"]*)")? should not contain "([^\"]*)"$/ do |field, selector, value|
  with_scope(selector) do
    expect(find_field(field).value).not_to match(/#{value}/)
  end
end

Then /^the "([^\"]*)" checkbox(?: within "([^\"]*)")? should be checked$/ do |label, selector|
  with_scope(selector) do
    expect(find_field(label)['checked']).to be_truthy
  end
end

Then /^the "([^\"]*)" checkbox(?: within "([^\"]*)")? should not be checked$/ do |label, selector|
  with_scope(selector) do
    expect(find_field(label)['checked']).to be_falsey
  end
end
 
Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).select(:path).compact.join('?')
  expect(current_path).to  eq(path_to(page_name))
end

Then /^(?:|I )should have the following query string:$/ do |expected_pairs|
  actual_params   = CGI.parse(URI.parse(current_url).query)
  expected_params = Hash[expected_pairs.rows_hash.map{|k,v| [k,[v]]}]
  expect(actual_params).to eq(expected_params)
end

Then /^show me the page$/ do
  save_and_open_page
end

Then /^show me the page and debug$/ do
  save_and_open_page
  require "rubygems"; require "byebug"; byebug
  1 #intentionally force debugger context in this method 
end

