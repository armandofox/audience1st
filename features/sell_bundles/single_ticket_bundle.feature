Feature: sell bundles of tickets with preassigned dates
  
  As a customer
  To save money on multiple shows
  I want to buy bundles whose vouchers have preset dates

Background: my cart contains a fixed-date-bundle voucher

  And a bundle "Shakespeare Combo" for $20.00 containing:
    | show      | date              | qty |
    | Hamlet    | May 12, 2010, 8pm |   1 |
    | King Lear | May 13, 2010, 8pm |   1 |
  And I am logged in as customer "Tom Foolery"
  And my cart contains 2 "Shakespeare Combo - $20.00" bundles
  
Scenario: enough seats available for both shows

  When the order is placed successfully
  Then I should be on the order confirmation page
  Then customer "Tom Foolery" should have the following vouchers:
  | vouchertype        | quantity | showdate          |
  | Hamlet (bundle)    |        2 | May 12, 2010, 8pm |
  | King Lear (bundle) |        2 | May 13, 2010, 8pm |
  | Shakespeare Combo  |        2 |                   |
