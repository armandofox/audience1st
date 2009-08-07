Given /^I (.*)visit the Store page$/ do |m|
  get '/customers/logout' if match =~ /first/i
  get '/store'
end

When /^I login as (.*)subscriber (.*)$/ do |m,name|
  @customer = Customer.create!(:first_name => name)
  @customer.stub!(:is_subscriber?).and_return(m !~ /non/)
  login_from_password(@customer)
end

Then /^I should see the (.*) message$/ do |m|
  response.should have_selector("div.StoreBanner#{match}")
end
