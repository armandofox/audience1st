Feature: login errors should appear

  As a customer who is trying to login
  So that I can know why I couldn't login
  I want to see error messages when login fails

Background:

  Given customer "Tom Foolery" has email "tom@foolery.com" and password "pass"
  And I am not logged in
  When I visit the Login page

Scenario: customer sees incorrect email if they type it in wrong
  When I fill in "email" with "to@foolery.com"
  And I fill in "password" with "ajsdkfla"
  And I press "Login"
  Then I should see "can't find that email in our database"

Scenario: customer should not see error message on successful login
  When I fill in "email" with "to@foolery.com"
  And I fill in "password" with "ajsdkfla"
  And I press "Login"
  And I fill in "email" with "tom@foolery.com"
  And I fill in "password" with "pass"
  And I press "Login"
  Then customer "Tom Foolery" should be logged in
  And I should not see "Login failed"
