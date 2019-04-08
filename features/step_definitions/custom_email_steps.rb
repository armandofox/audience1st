Then /^an email should be sent to( customer)? "(.*?)" containing "(.*)"$/ do |cust,recipient,link|
  recipient = find_customer(*recipient.split(/\s+/)).email if cust
  @email = ActionMailer::Base.deliveries.first
  @email.should_not be_nil
  @email.to.should include(recipient)
  @email.body.should include(link)
end

Then /^no email should be sent to( customer)? "(.*)"$/ do |cust,recipient|
  recipient = find_customer(*recipient.split(/\s+/)).email if cust
  ActionMailer::Base.deliveries.any? { |e| e.to.include?(recipient) }.should be_falsey
end

# Needs magic_link implementation
Given /^customer "(.*)" clicks on "(.*)"$/ do |cust,link|
  visit link
end  

When /^I seed with (\d+)$/ do |seed|
  srand(seed.to_i)
end