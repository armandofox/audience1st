@stubs_successful_credit_card_payment
Feature: view customer's orders

  As an admin
  So that i can help resolve customer problems
  I want to view a customer's past orders

Background: customer with orders

  Given an order for customer "Tom Foolery" paid with "credit card" containing:
  | show    | qty | type    | price | showdate             |
  | Chicago |   2 | General |  7.00 | May 15, 2010, 8:00pm |
  | Chicago |   1 | Special |  5.00  | May 15, 2010, 8:00pm |
  And that order has the comment "Pickup by: Al Foolery"

Scenario: view correct order info

  Given I am logged in as boxoffice manager
  When I visit the orders page for customer "Tom Foolery"
  Then I should see the following details for that order:
  | content                           |
  | Purchaser: Tom Foolery            |
  | Gift? No                          |
  | Order total: $19.00 (Credit card) |
  And I should not see the following details for that order:
  | Comments: Pickup by: Al Foolery   |
 
