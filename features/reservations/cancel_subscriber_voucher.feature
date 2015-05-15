Feature: subscriber can make subscriber reservations

  As a subscriber
  So that I can conveniently enjoy subscription benefits
  I want to be able to cancel my subscriber reservation online

Background: I have 2 subscriber vouchers reserved for a show

  Given a performance of "Hairspray" on May 1, 8pm
  And customer "Tom Foolery" has 2 subscriber reservations for that performance
  And I am logged in as customer "Tom Foolery"
  And I press "Click to Cancel"
  Then I should see "Your reservations have been cancelled"
  And  customer Tom Foolery should have 0 "Hairspray (Subscriber)" tickets for "Hairspray" on May 1, 8pm
  


