@javascript
Feature: transfer vouchers

  As a box office manager
  So that I can help customers who didn't know what they were doing when buying a gift
  I want to transfer vouchers from one account to another

Background: customer has purchased one or more subscriptions

  Given the "Full Season" subscription includes the following vouchers:
  | quantity | name     |
  |        1 | Nunsense |
  |        1 | Ragtime  |
  And an order for customer "Tom Foolery" containing the following tickets:
  | quantity | name        |
  |        2 | Full Season |
  And I am logged in as boxoffice manager
  And customer "Chris Jones" exists

Scenario: transfer one subscription

  When I visit the transfer vouchers page for customer "Tom Foolery"
  And I check the transfer box for the 1st "Full Season" voucher
  And I select customer "Chris Jones" within "transfer"
  And I press "Transfer"
  Then I should be on the home page for customer "Chris Jones"
  And customer "Chris Jones" should have the following vouchers:
  | quantity | vouchertype           |
  |        1 | Full Season           |
  |        1 | Nunsense (subscriber) |
  |        1 | Ragtime (subscriber)  |
