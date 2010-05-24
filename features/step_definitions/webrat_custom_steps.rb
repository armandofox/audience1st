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

Then /^the "([^\"]*)" menu should contain "([^\"]*)"$/ do |menu,choice|
  response.should(have_tag("select[id=#{menu}]") || have_tag("select[name=#{menu}]")) do |m|
    m.should have_selector("option", :content => choice)
  end
end

Then /^I should see the "(.*)" message$/ do |m|
  response.should(have_selector("div##{m}") || have_selector("div.#{m}"))
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
  attach_file :import_uploaded_data, File.join(RAILS_ROOT, 'spec', 'import_templates', path, file)
  click_button "Preview Import"
end

  
