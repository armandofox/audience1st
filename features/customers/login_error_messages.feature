Feature: login errors should appear

  As a customer who is trying to login
  So that I can know why I couldn't login
  I want to see error messages when login fails

Background:

  Given customer "Tom Foolery" has email "tom@foolery.com" and password "pass"
  Given I am not logged in
  When I visit the Login page

Scenario: customer sees incorrect email if they type it in wrong
  And I fill in "email" with "to@foolery.com"
  And I fill in "password" with "ajsdkfla"
  And I press "Login"
  Then I should see "Sorry, incorrect Email/Password"

Scenario: customer should not see error message on successful login
  And I fill in "email" with "to@foolery.com"
  And I fill in "password" with "ajsdkfla"
  And I press "Login"
  And I fill in "email" with "tom@foolery.com"
  And I fill in "password" with "pass"
  And I press "Login"
  Then I should not see "Sorry, incorrect Email/Password"
