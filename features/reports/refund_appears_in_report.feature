@stubs_successful_refund
@stubs_successful_credit_card_payment
Feature: refund appears as separate item in reports

  As a box office manager
  So that I can clearly track refunds of purchase transactions
  I want to see both the original purchase and the refund in the revenue details report

  Background: items purchased and then refunded

    Given I am logged in as boxoffice manager
    And a "SeasonSub" subscription available to anyone for $75.00
    And the following orders have been placed:
      |       date | customer    | item1        | item2        | payment     |
      | 2009-12-21 | Tom Foolery | 2x SeasonSub | $20 donation | credit card |
    And I refund item 1 of that order
    And a comp order for customer "Armando Fox" containing 1 "Staff" comp to "Chicago"
    And I refund item 5 of order 2

  Scenario: purchase and refund transactions both appear in report

    When I view revenue by payment type from "2009-12-20" to "2010-01-05"
    Then table "#table_credit_card_1" should include:
      | Item | Description                                                                                          | Sold on          | Amount  |
      |    1 | [CANCELED Mary Manager January 01, 2010 00:00] 75.00 SeasonSub (Show - Saturday, Jan 2, 8:00 PM) [1] | 2009-12-21 00:00 | $75.00  |
      |    2 | Show - Saturday, Jan 2, 8:00 PM SeasonSub                                                            | 2009-12-21 00:00 | $75.00  |
      |    3 | Donation to General Fund                                                                             | 2009-12-21 00:00 | $20.00  |
      |    4 | 	[REFUND for item 1]                                                                                 | 2010-01-01 00:00 | -$75.00 |

  Scenario: refund does not appear if outside date range
    
    When I view revenue by payment type from "2009-12-20" to "2009-12-31"
    Then table "#table_credit_card_1" should not include:
      | Item | Description                 | Sold on          | Amount  |
      |    4 | 	[REFUND for item 1]        | 2010-01-01 00:00 | -$75.00 |
    But table "#table_credit_card_1" should include:
      | Item | Description                                                                                          | Sold on          | Amount |
      |    1 | [CANCELED Mary Manager January 01, 2010 00:00] 75.00 SeasonSub (Show - Saturday, Jan 2, 8:00 PM) [1] | 2009-12-21 00:00 | $75.00 |
      |    2 | Show - Saturday, Jan 2, 8:00 PM SeasonSub                                                            | 2009-12-21 00:00 | $75.00 |
      |    3 | Donation to General Fund                                                                             | 2009-12-21 00:00 | $20.00 |

  Scenario: purchase does not appear if outside date range
    
    When I view revenue by payment type from "2009-12-31" to "2010-01-02"
    Then table "#table_credit_card_1" should not include:
      | Item | Description                                                                                          | Sold on          | Amount |
      |    1 | [CANCELED Mary Manager January 01, 2010 00:00] 75.00 SeasonSub (Show - Saturday, Jan 2, 8:00 PM) [1] | 2009-12-21 00:00 | $75.00  |
      |    2 | Show - Saturday, Jan 2, 8:00 PM SeasonSub                                                            | 2009-12-21 00:00 | $75.00  |
      |    3 | Donation to General Fund                                                                             | 2009-12-21 00:00 | $20.00  |
    But table "#table_credit_card_1" should include:
      | Item | Description                 | Sold on          | Amount  |
      |    4 | 	[REFUND for item 1]        | 2010-01-01 00:00 | -$75.00 |
