Feature: customer who forgot password can receive a link to reset

  As a customer who forgot my password
  So that I can login
  I want to generate a link to reset by email

Background:
  Given it is currently 'January 1, 2019 12:00'
  And customer "John Doe" exists

Scenario: send magic link to user

  When I ask to send a password reset email to "John@DOE.com"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=test_token"
  Given it is currently 'January 1, 2019 12:09'
  When "john@doe.com" opens the email
  And customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=test_token" 
  Then I should be on the change password page

Scenario: no forgot password email is sent if email does not exist

  When I ask to send a password reset email to "bchillz@gmail.com"
  Then I should be on the forgot password page 
  And I should see "is not in our database. You might try under a different email, or create a new account."

Scenario: invalid magic link does not work

  When I ask to send a password reset email to "john@doe.com"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=test_token"
  When customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=invalid_token"
  Then I should be on the login page
  But customer "John Doe" should not be logged in

Scenario: magic link expires after 10 minutes

  When I ask to send a password reset email to "john@doe.com"
  Then an email should be sent to "john@doe.com" containing "http://www.example.com/customers/reset_token?token=test_token"
  Given it is currently 'January 1, 2019 12:11'
  When "john@doe.com" opens the email
  And customer "john@doe.com" clicks on "http://www.example.com/customers/reset_token?token=test_token" 
  Then I should be on the login page
  But customer "John Doe" should not be logged in
  
  
  
  
  

  
