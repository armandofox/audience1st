Then /^show page and debug/ do
  save_and_open_page
  1
end

Then /^debug/ do
  require "rubygems"; require "byebug"; byebug
  1 #intentionally force debugger context in this method 
end

Then /^debug javascript$/ do
  page.driver.debug
  1
end
