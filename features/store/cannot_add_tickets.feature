Feature: Cannot add tickets

  As a box office manager
  So that I can control when tickets go on sale
  I want to prevent customers from adding tickets that aren't on sale yet or are sold out

Background: show with 3 tickets available

  Given I am logged in as customer "Tom Foolery"

  Scenario: Cannot buy tickets that aren't on sale yet

  Given a show "The Nerd" with the following tickets available:
  | qty | type    | price  | showdate                |
  |   3 | General | $15.00 | October 1, 2010, 7:00pm |
  And today is December 1, 2009
  When I go to the store page
  Then I should see "Tickets of this type not on sale until" within "#voucher_menus"

Scenario: Cannot buy tickets to sold-out performance

  And a performance of "The Nerd" on October 1, 2010, 7:00pm
  And the "Oct 1, 2010, 7:00pm" performance has reached its max sales
  When I go to the store page
  Then I should see "Event is sold out" within "#voucher_menus"

Scenario: Cannot buy past max sales

  Given a show "The Nerd" with the following tickets available:
    | qty | type    | price  | showdate                |
    |   3 | General | $15.00 | October 1, 2010, 7:00pm |
  When I go to the store page
  Then the "General - $15.00" menu should have options: 0;1;2;3

Scenario: Cannot buy past max sales even if combining ticket types
  
  And a show "The Nerd" with the following tickets available:
    | qty | type    | price  | showdate                |
    |   1 | General | $15.00 | October 1, 2010, 7:00pm |
    |   2 | Senior  | $10.00 | October 1, 2010, 7:00pm |
  And an advance sales limit of 2 for the October 1, 2010, 7:00pm performance
  When I go to the store page
  And I select "1" from "General - $15.00"
  And I select "2" from "Senior - $10.00"
  And I proceed to checkout
  Then I should see "Sorry, only 2 seats left for this performance."
  
  
