Then /^an email should be sent to( customer)? "(.*?)"( matching "(.*)" with "(.*)")?$/ do |cust,recipient,_,match_var,regex|
  recipient = find_customer(*recipient.split(/\s+/)).email if cust
  @email = ActionMailer::Base.deliveries.first
  @email.should_not be_nil
  @email.to.should include(recipient)
  if match_var
    match = @email.body.match( Regexp.new regex )
    match[1].should_not be_nil
    instance_variable_set "@#{match_var}", match[1]
  end
end

Then /^no email should be sent to( customer)? "(.*)"$/ do |cust,recipient|
  recipient = find_customer(*recipient.split(/\s+/)).email if cust
  ActionMailer::Base.deliveries.any? { |e| e.to.include?(recipient) }.should be_falsey
end

Given /^customer "(.*)" has email "(.*)"$/ do |customer,email|
  
end
