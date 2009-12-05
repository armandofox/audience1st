Feature: Add tickets to order

  As a patron
  So that I can go to a performance
  I want to add tickets to my order

  Background:
    Given a performance of "Bus Stop" on January 10, 2010 with 5 "General" tickets available at $15.00 each


  Scenario: Add tickets to order when not logged in
    Given I am not logged in
    And I go to the store page
    Then the "Show" field should contain "Bus Stop"
    
  
