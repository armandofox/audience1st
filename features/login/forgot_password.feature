Feature: customer who forgot password can receive a new one by email

  As a customer who forgot my password
  So that I can login
  I want to generate a new password by email

Scenario: reset password and login with new one

  Given customer "John Doe" exists and was created by admin
  When I visit the forgot password page
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" matching "password" with "Your new password is:\s*(\S*)\s*"
  And I should be able to login with username "john@doe.com" and that password

Scenario: send magic link to user
  Given customer "John Doe" exists and was created by admin
  When I visit the forgot password page
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" matching "magic_link" with "(.*)"
  Given "john@doe.com" opens the email
  And customer "john@doe.com" clicks on "magic_link" 
  Then I should be on the change password page
  And "John Doe" should be logged in

Scenario: no forgot password email is sent if email does not exist
  Given there is no customer named "bchillz@gmail.com"
  When I visit the forgot password page
  And I fill in "email" with "bchillz@gmail.com"
  And I press "Reset My Password By Email"
  Then I should be on the forgot password page 
  And I should see "is not in our database. You might try under a different email, or create a new account."

Scenario: magic link expires after 15 minutes
  Given customer "John Doe" exists and was created by admin
  When I visit the forgot password page
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" matching "magic_link" with "(.*)"
  When I note the time
  And I wait 900 seconds
  And "john@doe.com" opens the email
  And customer "john@doe.com" clicks on "magic_link"
  Then I should be on the link expired page
  And "John Doe" should not be logged in
  
  
  
  
  

  
