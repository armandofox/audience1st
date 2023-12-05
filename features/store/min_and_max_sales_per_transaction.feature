Feature: enforce minimum and maximum sales per transaction for a particular voucher type

  As a boxoffice manager
  So that I can offer Buy One Get One and similar promotions
  I want to enforce both a minimum and maximum number of tickets that can be purchased in one sale

  Background: performance with minimum and maximum purchase limits on a promotional ticket

    Given a show "The Nerd" with 5 "General" tickets for $10.00 on "Oct 1, 2010, 7pm"
    And "General" tickets for that performance must be purchased at least 3 and at most 4 at a time

  Scenario: cannot add fewer than minimum tickets per transaction to cart

    Given 1 "General" tickets have been sold for "Oct 1, 2010, 7pm"
    When I go to the store page
    Then the "General - $10.00" menu should have options: 0;3;4

  Scenario: cannot add fewer than minimum tickets per transaction to cart, nor more than available

    Given 2 "General" tickets have been sold for "Oct 1, 2010, 7pm"
    When I go to the store page
    Then the "General - $10.00" menu should have options: 0;3

  Scenario: when minimum purchase per txn exceeds number of tickets of that type remaining, should show as sold out

    Given 3 "General" tickets have been sold for "Oct 1, 2010, 7pm"
    When I go to the store page
    Then the "General - $10.00" menu should have options: 0


      
