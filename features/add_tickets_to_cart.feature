Feature: Add tickets to cart

  As a patron
  So that I can go to a performance
  I want to add tickets to my order

  Background:
    Given a performance of "Bus Stop" on January 10, 2010 with 5 "General" tickets available at $15.00 each
    And I go to the store page
    Then the "Show" field should contain "Bus Stop"
    And the "Date" field should contain "January 10"

  Scenario:  Add regular tickets to order when not logged in  
