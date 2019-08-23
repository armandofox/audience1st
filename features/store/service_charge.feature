@stubs_successful_credit_card_payment
Feature: add service charge to an order

  As a box office manager
  To neutralize my costs
  I want to be able to add a per-order service charge

Background: per-order service charges have been set up

  And I am logged in as customer "Tom Foolery"
  And a "Regular Sub" subscription available to anyone for $50.00
  And   the setting "subscription order service charge description" is "Sub Fee"
  And   the setting "subscription order service charge" is "2.50"

Scenario: service charge on subscription order

  Given my cart contains 1 "Regular Sub" subscriptions

  Then I should be on the checkout page for customer "Tom Foolery"
  And the cart should show the following items:
  | description | price | 
  | Regular Sub | 50.00 | 
  | Sub Fee     |  2.50  | 
  And the cart total price should be 52.50

  When I place my order with a valid credit card
  Then customer "Tom Foolery" should have the following vouchers:
  | vouchertype | quantity |
  | Regular Sub |        1 |
  And  customer "Tom Foolery" should have the following items:
  | type       | amount | comments | account_code |
  | RetailItem |   2.50 | Sub Fee  |         0000 |

Scenario: service charge on regular order
  
  Given the setting "regular order service charge description" is "Order Fee"
  And   the setting "regular order service charge" is "3.50"
  And my cart contains the following tickets:
  | show    | qty | type    | price | showdate             |
  | Chicago |   3 | General |  7.00 | May 15, 8:00pm   |
  Then the cart total price should be 24.50

  When I place my order with a valid credit card
  Then customer "Tom Foolery" should have 3 "General" tickets for "Chicago" on May 15, 8pm
  And  customer "Tom Foolery" should have the following items:
  | type       | amount | comments  | account_code |
  | RetailItem |   3.50 | Order Fee |         0000 |


Scenario: service charge is not added twice if order error first time

  Given I am on the subscriptions page for customer "Tom Foolery"
  And I proceed to checkout
  Then I should be on the subscriptions page for customer "Tom Foolery"
  And I should see the message for "store.errors.empty_order"
  When I add 1 "Regular Sub" subscriptions
  Then the cart total price should be 52.50

