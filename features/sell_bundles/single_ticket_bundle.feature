Feature: sell bundles of tickets with preassigned dates
  
  As a customer
  To save money on multiple shows
  I want to buy bundles whose vouchers have preset dates

Background: my cart contains a fixed-date-bundle voucher

  Given today is May 1, 2013
  And a bundle "Shakespeare Combo" containing:
    | show      | date              | qty |
    | Hamlet    | May 12, 2013, 8pm |   1 |
    | King Lear | May 13, 2013, 8pm |   1 |
  And I am logged in as customer "Tom Foolery"
  And my cart contains 2 "Shakespeare Combo - $20.00" bundle vouchers
  
Scenario: enough seats available for both shows

  When the order is placed successfully
  Then customer Tom Foolery should have 2 "Hamlet (bundle)" tickets reserved for "Hamlet" on May 12, 2013, 8pm
  And  customer Tom Foolery should have 2 "King Lear (bundle)" tickets reserved for "King Lear" on May 13, 2013, 8pm
