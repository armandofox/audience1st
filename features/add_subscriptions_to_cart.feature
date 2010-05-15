@wip
Feature: Add subscriptions to cart

  As a patron
  So that I can become a season subscriber
  I want to add subscriptions to my order

  Background:
    Given a "Regular Sub" subscription available to anyone for $50.00
    And I go to the subscriptions page
    Then I should see "Buy Subscriptions"
    And I should see a quantity menu for "Regular Sub"

  Scenario:  Add subscriptions to order when not logged in  


