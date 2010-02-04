require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))


# A dropdown menu of quantities associated with a particular voucher type.
# Capture the vouchertype label so we can refer to it later.

Then /^I should see a quantity menu for "([^\"]*)"$/ do |name|
  flunk
end

Then /^the "([^\"]*)" menu should contain "([^\"]*)"$/ do |menu,name|
  response_body.should have_selector("select[name='#{menu}']") do |elt|
    debugger
    elt.should have_selector("option", :content => name), elt
  end
end
