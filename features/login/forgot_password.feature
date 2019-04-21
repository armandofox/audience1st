Feature: customer who forgot password can receive a link to reset

  As a customer who forgot my password
  So that I can login
  I want to generate a link to reset by email

Background:
  Given it is currently 'January 1, 2019 12:00'
  And customer "John Doe" exists and was created by admin
  When I visit the forgot password page

Scenario: send magic link to user
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=test_token"
  Given "john@doe.com" opens the email
  And it is currently 'January 1, 2019 12:09'
  And customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=test_token" 
  Then I should be on the change password page

Scenario: no forgot password email is sent if email does not exist
  And I fill in "email" with "bchillz@gmail.com"
  And I press "Reset My Password By Email"
  Then I should be on the forgot password page 
  And I should see "is not in our database. You might try under a different email, or create a new account."

Scenario: invalid magic link does not work
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=test_token"
  And customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=invalid_token"
  And I should be on the login page
  And customer "John Doe" should not be logged in

Scenario: magic link expires after 10 minutes
  And I fill in "email" with "john@doe.com"
  And I press "Reset My Password By Email"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=test_token"
  Given "john@doe.com" opens the email
  And it is currently 'January 1, 2019 12:11'
  And customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=test_token" 
  And I should be on the login page
  And customer "John Doe" should not be logged in
  
  
  
  
  

  
