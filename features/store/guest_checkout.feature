@stubs_successful_credit_card_payment
Feature: Guest checkout

  As a box office manager
  So that I can entice people to buy tickets
  I want to enable guest checkout, so patrons just give email & billing

  Background: 

    Given I am not logged in  
    And   my cart contains the following tickets:
      | show    | qty | type    | price | showdate             |
      | Chicago |   3 | General |  7.00 | May 15, 2010, 8:00pm |
    And I follow "Checkout as Guest"
    And I fill in the ".billing_info" fields with "Al Smith, 123 Fake St., Alameda, CA 94501, 510-999-9999, alsmith@mail.com"

  Scenario: successful first-time guest checkout for single-ticket purchases
    When I press "CONTINUE >>"
    Then I should be logged in as "Al Smith"
    Then I should be on the checkout page
    And the 

  Scenario: after successful guest checkout I should no longer be logged in

  Scenario: multiple guest checkouts to same email credit tickets to same account
      
  Scenario: no guest checkout allowed for subscription purchases or camps

    Given a "Regular" subscription available to anyone for $50.00
    When I go to the subscriptions page
    When I select "1" from "Regular"
    And I press "CONTINUE >>"

  Scenario: if guest checkout fails because of existing account, checkout continues successfully after login
      
  






   
