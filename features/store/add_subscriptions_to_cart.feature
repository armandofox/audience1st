Feature: Add subscriptions to cart

  As a patron
  So that I can become a season subscriber
  I want to add subscriptions to my order

  Background:
    Given I am not logged in

  Scenario: Add subscription to order when not logged in
    Given a "Regular Sub" subscription available to anyone for $50.00
    When I go to the subscriptions page
    Then I should see "Buy Subscriptions"
    When I select "2" from "Regular Sub"
    And I press "CONTINUE >>"
    Then the cart should contain 2 "Regular Sub" subscriptions
