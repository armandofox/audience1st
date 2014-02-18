Feature: Add subscriptions to cart

  As a patron
  So that I can become a season subscriber
  I want to add subscriptions to my order

  Scenario: Add subscription to order when not logged in
    Given a "Regular Sub" subscription available to anyone for $50.00
    When I go to the subscriptions page
    Then I should see "Buy Subscriptions"
    When I select "2" from "Regular Sub"
    And I press "CONTINUE >>"
    Then show me the page
    Then I should be on the Checkout page
    And I should see "100.00" within "#cart_total"

