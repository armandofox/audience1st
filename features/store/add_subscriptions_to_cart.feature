@javascript
Feature: Add subscriptions to cart

  As a patron
  So that I can become a season subscriber
  I want to add subscriptions to my order

  Background:
    Given I am not logged in

  Scenario: Add subscription to order when not logged in

    Given a "Regular" subscription available to anyone for $50.00
    And a "Discount" subscription available to anyone for $20.00
    When I go to the subscriptions page
    And I select "2" from "Regular"
    And I select "1" from "Discount"
    And I proceed to checkout
    Then the cart should contain 2 "Regular" subscriptions
    And  the cart should contain 1 "Discount" subscriptions
    And the cart total price should be $120.00
