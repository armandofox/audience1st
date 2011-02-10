Feature: Add tickets to cart

  As a patron
  So that I can attend a performance
  I want to add tickets to my order

Background:

  Given a show "Bus Stop" with "General" tickets for $15.00 on "January 10, 2013, 8:00pm"
  And today is January 9, 2013
  When I go to the store page
  Then the "show" menu should contain "Bus Stop"
  And the "showdate" menu should contain "Thursday, Jan 10,  8:00 PM"

Scenario:  Add regular tickets to order when not logged in  
