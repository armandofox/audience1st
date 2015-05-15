@stubs_successful_credit_card_payment
Feature: Successful checkout when not starting as logged in

  As a patron
  So that I can get to ticket choices quickly
  I want to start the purchase flow before logging in

Background:

  Given I am not logged in
  And I add the following tickets:
  | show    | qty | type    | price | showdate             |
  | Chicago |   3 | General |  7.00 | May 15, 2010, 8:00pm |
  Then I should be on the login page
  When I login as customer "Tom Foolery"
  Then I should be on the checkout page
  And the billing customer should be "Tom Foolery"
  When I place my order with a valid credit card
  Then I should be on the order confirmation page
  And I should see "You have paid a total of $21.00 by Credit card"
  And customer Tom Foolery should have 3 "General" tickets for "Chicago" on May 15, 2010, 8:00pm
