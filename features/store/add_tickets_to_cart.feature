@javascript
Feature: Add tickets to cart

  As a patron
  So that I can attend a performance
  I want to add tickets to my order

Background:

  Given today is May 9, 2011
  And   a show "Bus Stop" with 8 "General" tickets for $15.00 on "May 10, 2011, 8:00pm"
  When  I go to the store page

Scenario:  Add regular tickets to order when not logged in  

  When I select "3" from "General"
  Then the "Order Total" field should contain "45.00"
    
