@time
Feature: Cannot add tickets

  As a box office manager
  So that I can control when tickets go on sale
  I want to prevent customers from adding tickets that aren't on sale yet or are sold out

Background: show with 3 tickets available

  Given a show "The Nerd" with the following tickets available:
  | qty | type    | price  | showdate                |
  |   3 | General | $15.00 | October 1, 2013, 7:00pm |
  And I am logged in as customer "Tom Foolery"

Scenario: Cannot buy tickets that aren't on sale yet

  Given today is June 1, 2013
  When I go to the store page
  Then I should see "Tickets of this type not on sale until" within "#voucher_menus"

Scenario: Cannot buy tickets to sold-out performance

  Given today is September 30, 2013
  And the "Oct 1, 2013, 7:00pm" performance is sold out
  When I go to the store page
  Then I should see "Event is sold out" within "#voucher_menus"


  

  
