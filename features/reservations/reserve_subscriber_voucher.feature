@javascript
Feature: subscriber can make subscriber reservations

  As a subscriber
  So that I can conveniently enjoy subscription benefits
  I want to make subscriber reservations online

Background: show with at least one available performance

  Given there is a show named "Hairspray" with showdates:
  | date       | tickets_sold |
  | May 1, 8pm |            0 |
  | May 3, 8pm |          100 |
  And customer "Tom Foolery" has 2 of 2 open subscriber vouchers for "Hairspray" 
  And I am logged in as customer "Tom Foolery"
  And I am on the home page for customer "Tom Foolery"

Scenario: reserve all vouchers for available performance

  When I select "2" from "number"
  And I select "Saturday, May 1, 8:00 PM" from "showdate_id"
  And I press "Confirm"
  Then customer "Tom Foolery" should have 2 "Hairspray (Subscriber)" tickets for "Hairspray" on May 1, 8pm

Scenario: reserve single voucher for available performance

  When I select "1" from "number"
  And I select "Saturday, May 1, 8:00 PM" from "showdate_id"
  And I press "Confirm"
  Then customer "Tom Foolery" should have 1 "Hairspray (Subscriber)" tickets for "Hairspray" on May 1, 8pm

Scenario: customer cannot reserve sold out performance

  When I select "1" from "number"
  And I select "Monday, May 3, 8:00 PM (Not available)" from "showdate_id"
  And I press "Confirm"
  Then I should see "Your reservations could not be completed"
  And  customer "Tom Foolery" should have 0 "Hairspray (Subscriber)" tickets for "Hairspray" on May 1, 8pm

Scenario: boxoffice can reserve sold out performance

  Given I am logged in as box office
  And I am on the home page for customer "Tom Foolery"
  When I select "2" from "number"
  And I select "Monday, May 3, 8:00 PM" from "showdate_id"
  And I press "Confirm"
  Then customer "Tom Foolery" should have 2 "Hairspray (Subscriber)" tickets for "Hairspray" on May 3, 8pm
  And the Monday, May 3, 8pm performance should be oversold by 2
