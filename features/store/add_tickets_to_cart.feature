Feature: Add tickets to cart

  As a logged-in patron
  So that I can attend a performance
  I want to quickly add tickets to my order

Background:

  Given a show "The Nerd" with the following tickets available:
  | qty | type    | price  | showdate                |
  |   3 | General | $15.00 | October 1, 2010, 7:00pm |
  And I am logged in as customer "Tom Foolery"
  And   I go to the store page

Scenario:  Add regular tickets to my order with no donation

  When I select "3" from "General - $15.00"
  And I proceed to checkout
  Then the billing customer should be "Tom Foolery"
  And the cart total price should be $45.00
  And the cart should contain 3 "General" tickets for "October 1, 2010, 7:00pm"
  And the cart should not contain a donation

Scenario: Add regular tickets to my order with a donation

  When I select "2" from "General - $15.00"
  And I fill in "donation" with "17"
  And I proceed to checkout
  Then I should be on the Checkout page
  And the cart total price should be $47.00
  And the cart should contain 2 "General" tickets for "October 1, 2010, 7:00pm"
  And the cart should contain a donation of $17.00 to "General Fund"  
