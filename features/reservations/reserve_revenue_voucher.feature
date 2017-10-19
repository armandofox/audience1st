Feature: non-subscribers can reserve multiple vouchers of the same type simultaneously

   As a non-subscriber
   So that I can conveniently reserve multiple vouchers of the same type
   I want a drop down window that lets me select how many tickets I want

Background: show with at least one available performance

  Given there is a show named "Hairspray" with showdates:
  | date       | tickets_sold |
  | May 1, 8pm |            0 |
  | May 3, 8pm |          100 |
  And customer "Tom Foolery" has 2 of 2 open subscriber vouchers for "Hairspray"
  And I am logged in as customer "Tom Foolery"
  And I am on the home page for customer "Tom Foolery"

Scenario: reserve multiple vouchers for one available performance and cancel one of the vouchers
  When I select "2" from "number"
  And I select "Saturday, May 1, 8:00 PM" from "showdate_id"
  And I press "Click to Confirm"
  Then customer Tom Foolery should have 2 "Hairspray (Subscriber)" tickets for "Hairspray" on May 1, 8pm
  And I am on the home page for customer "Tom Foolery"
  When I select "1" from "cancelnumber"
  And I press "Click to Cancel"
  Then customer Tom Foolery should have 1 "Hairspray (Subscriber)" tickets for "Hairspray" on May 1, 8pm
