Feature: subscriber can make subscriber reservations

  As a subscriber
  So that I can conveniently enjoy subscription benefits
  I want to be able to cancel my subscriber reservation online

Background: I have 2 subscriber vouchers reserved for a show called "Hairspray"

  Given I am logged in as customer "Tom Foolery"

Scenario: Cancel/change multiple reservation the customer want

  Given there is a show named "Hairspray" with showdates:
    | date       | tickets_sold |
    | May 1, 8pm |           10 |
    | May 3, 8pm |           10 |
  And customer "Tom Foolery" has 2 cancelable subscriber reservations for May 1, 8pm
  And I am on the home page for customer "Tom Foolery"
  When I select "1" from "cancelnumber"
  And I press "Cancel"
  Then I should see "1 of your reservations have been cancelled"
  And  customer "Tom Foolery" should have 1 "Hairspray (Subscriber)" tickets for "Hairspray" on May 1, 8pm

Scenario: for reserved seating shows, must cancel all at once

  Given a performance of "Hairspray" on "May 4, 8pm"
  And that performance has reserved seating
  And customer "Tom Foolery" has 2 cancelable subscriber reservations with seats "A1,B2" for May 4, 8pm
  And I am on the home page for customer "Tom Foolery"
  Then I should not see a menu named "cancelnumber"
  And I should see "2" within ".cancelnumber"
  When I press "Cancel"
  Then I should see "2 of your reservations have been cancelled"
  And  customer "Tom Foolery" should have 0 "Hairspray (Subscriber)" tickets for "Hairspray" on May 4, 8pm
