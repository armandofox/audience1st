Feature: Checkout

  As a patron
  So that I can purchase my tickets 
  I want to checkout and get to the Place Order page

  Background:
    Given a cart totaling 25.00
    And a checkout is in progress
    And I am on the login page

  Scenario: successful login to existing account
    Given Tom has an account with login "tom@foolery.com" and password "foolery"
    When I fill in 'Login Name' with "tom@foolery.com"
    And I fill in 'Password' with "foolery"
    And I click 'Login'


  Scenario: unsuccessful login to existing account

  Scenario: not logged in and does not have an account

  Scenario: logged into account  

  
