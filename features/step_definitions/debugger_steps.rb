Then /^debug$/ do
  require "rubygems"; require "ruby-debug"; debugger 
  1 #intentionally force debugger context in this method 
end

Then /^debug javascript$/ do
  page.driver.debug
  1
end

