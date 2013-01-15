@stubs_successful_credit_card_payment
Feature: Successful checkout with credit card

  As a patron
  So that I can purchase my tickets 
  I want to checkout with a credit card

  Background:
    Given today is May 9, 2011
    And I am logged in as customer "Tom Foolery"
    And my cart contains the following tickets:
      | show    | qty | type    | price | showdate             |
      | Chicago |   3 | General |  7.00 | May 15, 2011, 8:00pm |
    And I should be on the checkout page

  Scenario: successful credit card payment
    When I place my order with a valid credit card
    Then I should be on the order confirmation page
    And I should see "You have paid a total of $21.00 by Credit card"


  Scenario: unsuccessful login to existing account

  Scenario: not logged in and does not have an account

  Scenario: logged into account  

  
