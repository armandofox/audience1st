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
  And my cart contains 2 "Shakespeare Combo - $20.00" bundles
  
Scenario: enough seats available for both shows

  When the order is placed successfully
  Then I should be on the order confirmation page
  Then customer Tom Foolery should have the following vouchers:
  | vouchertype        | quantity | showdate          |
  | Hamlet (bundle)    |        2 | May 12, 2013, 8pm |
  | King Lear (bundle) |        2 | May 13, 2013, 8pm |
  | Shakespeare Combo  |        2 |                   |
