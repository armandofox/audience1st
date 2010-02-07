Feature: Add tickets to cart

  As a patron
  So that I can attend a performance
  I want to add tickets to my order

  Background:
    Given a performance of "Bus Stop" on January 10, 2013
    And 5 "General" tickets available at $15.00 each
    And I go to the store page
    Then the "show" menu should contain "Bus Stop"
    And the "showdate" menu should contain /January 10/

  Scenario:  Add regular tickets to order when not logged in  
