require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

# For debugging help - dump actual HTML of a page to a file
Then /^\(?show me\)?$/ do
  save_and_open_page
  # name = response.request.request_uri.gsub(/[\/\#\?]/,'-')
  # File.open("/tmp/cucumber-#{name}.html", "w"){ |f| f.puts response.body }
  # system "open /tmp/cucumber-#{name}.html" 
end

# A dropdown menu of quantities associated with a particular voucher type.
# Capture the vouchertype label so we can refer to it later.

Then /^I should see a quantity menu for "([^\"]*)"$/ do |name|
  flunk
end

Then /^the "([^\"]*)" menu should contain "([^\"]*)"$/ do |menu,name|
  response_body.should have_selector("select[name='#{menu}']") do |elt|
    elt.should have_selector("option", :content => name), elt
  end
end

Then /^I should see the "(.*)" message$/ do |m|
  response.should (have_selector("div##{m}") || have_selector("div.#{m}"))
end
