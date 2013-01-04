Feature: Add tickets to cart

  As a logged-in patron
  So that I can attend a performance
  I want to quickly add tickets to my order

Background:

  Given today is May 9, 2011
  And   a show "Bus Stop" with 8 "General" tickets for $15.00 on "May 10, 2011, 8:00pm"
  And   I am logged in as customer "Tom Foolery"
  And   I go to the store page

Scenario:  Add regular tickets to my order with no donation

  When I select "3" from "General - $15.00"
  And I press "CONTINUE >>"
  Then I should be on the Checkout page
  And I should see "45.00" within "#cart_total"
  And the cart should contain 3 "General" tickets for "May 10, 2011, 8:00pm"
  And the cart should not contain a donation


