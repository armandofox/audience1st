@stubs_successful_credit_card_payment
Feature: revenue by payment type report

  As the financial manager
  So that I can reconcile my credit card and bank statements
  I want to see transactions subtotaled by payment type and account code

Background: 

  Given I am logged in as staff
  And a "SeasonSub" subscription available to anyone for $73.00
  And a show "Chicago" with the following tickets available:
  | qty | type     | price  | showdate                |
  | 100 | General  | $37.00 | October 1, 2010, 7:00pm |
  | 100 | Discount | $31.00 | October 1, 2010, 7:00pm |
  
  And the following account codes exist:
  | code | name            | used_for         |
  | 4040 | Regular tickets | General,Discount |
  | 5050 | Subscriptions   | SeasonSub        |
  | 6060 | Donations       | donations        |

  And the following orders have been placed:
    |       date | customer      | item1        | item2        | payment     |
    | 2010-02-01 | Tom Foolery   | 2x SeasonSub | $20 donation | credit card |
    | 2010-02-03 | Armando Fox   | 1x General   | 1x Discount  | credit card |
    | 2010-02-05 | Bilbo Baggins | 1x SeasonSub | $15 donation | check       |
    | 2010-02-08 | Barb Jones    |              | $18 donation | cash        |

Scenario: Transactions within date range should appear

  When I view revenue by payment type from "2010-02-01" to "2010-02-28"
  Then the "credit_card" subtotals should be exactly:
    | account_code |  total |
    |         4040 |  68.00 |
    |         5050 | 146.00 |
    |         6060 |  20.00 |
  And the "cash" subtotals should be exactly:
    | account_code | total |
    |         4040 |  0.00 |
    |         5050 |  0.00 |
    |         6060 | 18.00 |
  And the "check" subtotals should be exactly:
    | account_code | total |
    |         4040 |  0.00 |
    |         5050 | 73.00 |
    |         6060 | 15.00 |


Scenario: View transactions within narrower date range

  When I view revenue by payment type from "2010-02-03" to "2010-02-05"  
  Then the "credit_card" subtotals should be exactly:
    | account_code | total |
    |         4040 | 68.00 |
    |         5050 |  0.00 |
    |         6060 |  0.00 |
  And the "cash" subtotals should be exactly:
    | account_code | total |
    |         4040 |  0.00 |
    |         5050 |  0.00 |
    |         6060 |  0.00 |
  And the "check" subtotals should be exactly:
    | account_code | total |
    |         4040 |  0.00 |
    |         5050 | 73.00 |
    |         6060 | 15.00 |
