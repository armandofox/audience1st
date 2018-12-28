@stubs_successful_credit_card_payment
Feature: different ways to checkout for regular patrons and admins

  As a box office manager
  To accept cash or checks at the boxoffice
  I want to complete an order paying by cash or check

Background:

  Given I am logged in as boxoffice
  And customer "Armando Fox" exists
  
Scenario: admin remains logged in after purchasing for a customer who has never logged in

  When I add the following tickets for customer "Armando Fox":
    | show    | qty   | type    | price | showdate             |
    | Chicago | 2     | General |  7.00 | May 15, 2010, 8:00pm |
  And I press "Accept Cash Payment"
  Then I should see "You have paid a total of $14.00 by Cash"
  When I follow "Back to This Customer"
  Then I should be on the home page for customer "Armando Fox"
  And customer "Barry Boxoffice" should be logged in
  
Scenario Outline:

  When I add the following tickets for customer "Armando Fox":
    | show    | qty   | type    | price | showdate             |
    | Chicago | <qty> | General |  7.00 | May 15, 2010, 8:00pm |
  Then I should be on the checkout page for customer "Armando Fox"
  When I press "<button>"
  And I should see "You have paid a total of <total_amount> by <method>"
  And customer "Armando Fox" should have <qty> "General" tickets for "Chicago" on May 15, 2010, 8:00pm
  And customer "Barry Boxoffice" should be logged in

Examples:

  | qty | total_amount | button               | method      |
  |   2 | $14.00       | Accept Check Payment | Check       |
  |   1 | $7.00        | Accept Cash Payment  | Cash        |
  |   3 | $21.00       | Charge Credit Card   | Credit card |
