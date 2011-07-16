Feature: Sell walkup tickets

  As a boxoffice worker
  I want to sell tickets to walkup customers
  So that we can maximize seat counts

  Background:
    Given a performance of "The Nerd" on October 1, 8:00pm
    And 3 General vouchers costing $11.00 are available for this performance
    And today is October 1, 7:00pm
    And I am logged in as a box office worker
    And I go to the walkup sales page
    Then I should see "The Nerd"
    And I should see /Oct\s+1,\s+8:00\s+PM/

  Scenario: purchase 2 tickets with cash

    When I select "2" from "General"
    And I press "Record Cash Payment or Zero Revenue Transaction"
    Then I should see "Successfully added 2 vouchers purchased via Box office - Cash"
    And I should see "General (1 left)"

  Scenario: purchase 2 tickets with check
  
    When I select "2" from "General"
    And I press "Record Check Payment"
    Then I should see "Successfully added 2 vouchers purchased via Box office - Check"
    And I should see "General (1 left)"

  Scenario: purchase 2 tickets with valid credit card info

    When I select "2" from "General"
    And I fill in the "Credit Card Payment" fields as follows:
    | field              | value               |
    | First Name         | John                |
    | Last Name          | Doe                 |
    | Type               | select "MasterCard" |
    | Number (no spaces) | 1                   |
    | Expiration Month   | select "12"         |
    | Expiration Year    | select "2015"       |
    And I fill in "Enter CVV code manually FIRST!" with "111"
    And I press "Submit Credit Card Charge"
    Then I should see "Successfully added 2 vouchers purchased via Box office - Credit Card"
    And I should see "General (1 left)"

  Scenario: attempt purchase with invalid credit card

    When I select "2" from "General"
    And I fill in the "Credit Card Payment" fields as follows:
    | field              | value               |
    | First Name         | John                |
    | Last Name          | Doe                 |
    | Type               | select "MasterCard" |
    | Number (no spaces) | 3                   |
    | Expiration Month   | select "12"         |
    | Expiration Year    | select "2015"       |
    And I press "Submit Credit Card Charge"
    Then I should see "Transaction NOT processed"
    And I should see "General (3 left)"

  Scenario: attempt zero-revenue purchase by check

    When I press "Record Check Payment"
    Then I should see "No tickets or donation to process"
    And I should see "General (3 left)"

