Feature: subscriber can make subscriber reservations

  As a subscriber
  So that I can conveniently enjoy subscription benefits
  I want to be able to cancel my subscriber reservation online

Background: I have 2 subscriber vouchers reserved for a show called "Hairspray"
  Given there is a show named "Hairspray" with showdates:
    | date       | tickets_sold |
    | May 1, 8pm |           10 |
    | May 3, 8pm |           10 |
  And customer "Tom Foolery" has 2 cancelable subscriber reservations for May 1, 8pm
  And I am logged in as customer "Tom Foolery"
  And I am on the home page for customer "Tom Foolery"

Scenario: Cancel/change multiple reservation the customer want
  When I select "1" from "cancelnumber"
  And I press "Cancel"
  Then I should see "1 of your reservations have been cancelled"
  And  customer "Tom Foolery" should have 1 "Hairspray (Subscriber)" tickets for "Hairspray" on May 1, 8pm


