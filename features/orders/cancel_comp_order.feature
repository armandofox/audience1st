Feature: refund a zero-cost order such as comps

  As a boxoffice manager
  I sometimes need to cancel a comp order

Background:

  Given I am logged in as boxoffice manager

Scenario: cancel a comp single-ticket order

  Given a comp order for customer "Armando Fox" containing 2 "StaffComp" comps to "Chicago"
  When I visit the orders page for customer "Armando Fox"
  And I cancel item 1 of that order
  Then I should see /CANCELED Mary Manager.*0\.00 StaffComp.*Chicago/
  And customer "Armando Fox" should have the following vouchers:
  | quantity | vouchertype |
  |        1 | StaffComp   |

Scenario: cancel a comp subscription

  Given a "Courtesy Sub" subscription available to boxoffice for $0.00
  And the "Courtesy Sub" subscription includes the following vouchers:
  | name     | quantity |
  | Chess    |        2 |
  | Hamilton |        1 |
  And an order of 2 "Courtesy Sub" comp subscriptions for customer "Armando Fox"
  When I visit the orders page for customer "Armando Fox"
  And I cancel item 5 of that order
  Then I should see /CANCELED Mary Manager.*0\.00 Courtesy Sub/
  And  I should see /CANCELED Mary Manager.*0\.00 Hamilton/
  And  I should see /CANCELED Mary Manager.*0\.00 Chess/
  Then customer "Armando Fox" should have the following vouchers:
    | quantity | vouchertype           |
    |        1 | Courtesy Sub          |
    |        1 | Hamilton (subscriber) |
    |        2 | Chess (subscriber)    |
