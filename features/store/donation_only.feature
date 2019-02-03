@stubs_successful_credit_card_payment
Feature: make a donation through regular sales flow

Background:
  Given I am logged in as customer "Tom Foolery"
  And I go to the store page

Scenario: make donation
  When I fill in "donation" with "15"
  And I proceed to checkout
  Then I should be on the Checkout page
  And the cart should contain a donation of $15.00 to "General Fund"
  And the billing customer should be "Tom Foolery"
  When I place my order with a valid credit card
  Then I should be on the order confirmation page
  And I should see "You have paid a total of $15.00 by Credit card"
  And customer "Tom Foolery" should have a donation of $15.00 to "General Fund"

