Then /^show me the page$/ do
  save_and_open_page
end

Then /show me a screenshot/ do
  save_and_open_screenshot
end

Then /^show me the page and debug$/ do
  save_and_open_page
  require "rubygems"; require "byebug"; byebug
  1 #intentionally force debugger context in this method 
end

Then /^debug/ do
  require "rubygems"; require "byebug"; byebug
  1 #intentionally force debugger context in this method 
end

Then /^debug javascript$/ do
  page.driver.debug
  1
end
