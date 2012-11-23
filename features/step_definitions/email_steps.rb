Then /^an email should be sent to "(.*)" containing a password$/ do |recipient|
  @email = ActionMailer::Base.deliveries.first
  @email.to.should include(recipient)
  match = @email.body.match( /Your new password is:\s*(\S*)\s*$/ )
  (@password = match[1]).should_not be_nil
end
