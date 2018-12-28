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
