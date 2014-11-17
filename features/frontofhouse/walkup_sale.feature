Feature: Sell walkup tickets

  As a boxoffice worker
  I want to sell tickets to walkup customers
  So that we can maximize seat counts

  Background:
    Given I am logged in as boxoffice
    And a show "The Nerd" with the following tickets available:
    | qty | type    | price  | showdate                |
    |   3 | General | $11.00 | October 1, 2015, 7:00pm |
    And I am on the walkup sales page for October 1, 2015, 7:00pm

  Scenario: purchase 2 tickets with cash

    When I select "2" from "General"
    And I press "Record Cash Payment or Zero Revenue Transaction"
    Then I should see "2 tickets paid by Cash"
    And I should see "General (1 left)"
    And I should be on the walkup sales page for October 1, 2015, 7:00pm

  Scenario: purchase 2 tickets with check
  
    When I select "2" from "General"
    And I press "Record Check Payment"
    Then I should see "2 tickets paid by Check"
    And I should see "General (1 left)"
    And I should be on the walkup sales page for October 1, 2015, 7:00pm

@stubs_successful_credit_card_payment
  Scenario: purchase 2 tickets with valid credit card info

    When I select "2" from "General"
    And I fill in the "Credit Card Payment" fields as follows:
    | field              | value         |
    | First Name         | John          |
    | Last Name          | Doe           |
    | Number (no spaces) | 1             |
    | Expiration Month   | select "12"   |
    | Expiration Year    | select "2013"   |
    And I fill in "Enter CVV code manually FIRST!" with "111"
    And I press "Charge Credit Card"
    Then I should see "2 tickets paid by Credit card"
    And I should see "General (1 left)"
    And I should be on the walkup sales page for October 1, 2015, 7:00pm

@stubs_failed_credit_card_payment
  Scenario: attempt purchase with invalid credit card

    When I select "2" from "General"
    And I fill in the "Credit Card Payment" fields as follows:
    | field            | value         |
    | First Name       | John          |
    | Last Name        | Doe           |
    | Expiration Month | select "12"   |
    | Expiration Year  | select "2013" |
    And I press "Charge Credit Card"
    Then I should see "Transaction NOT processed"
    And I should see "General (3 left)"
    And I should be on the walkup sales page for October 1, 2015, 7:00pm

  Scenario: attempt zero-revenue purchase by check

    When I press "Record Check Payment"
    Then I should see "There are no items to purchase"
    And I should see "General (3 left)"
    And I should be on the walkup sales page for October 1, 2015, 7:00pm

