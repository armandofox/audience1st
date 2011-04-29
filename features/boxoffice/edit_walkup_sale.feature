Feature: edit walkup sales after the fact

  As a box office manager
  So that I can correct common errors on walkup sales
  I want to change the performance associated with a walkup sale

Background:

  Given I am logged in as boxoffice
  And a show "Chicago" with the following tickets available:
  | qty | type     | price  | showdate              |
  |   5 | General  | $15.00 | April 7, 2010, 8:00pm |
  |   1 | Discount | $10.00 | April 8, 2010, 8:00pm |
  |   1 | General  | $15.00 | April 8, 2010, 8:00pm |
  And the following walkup tickets have been sold for "April 7, 2010, 8:00pm":
  | qty | type     | payment  |
  |   1 | General  | box_cash |
  And I am on the walkup sales report for "April 7, 2010, 8:00pm"
  Then I should see "General" within "#box_cash"

Scenario: box office can change walkup to same ticket type for another performance

  When I check "General" within "#box_cash"
  And I select "Thursday, Apr 8, 8:00 PM" from "to_showdate"
  And I press "Transfer"
  Then I should be on the walkup sales page for "April 7, 2010, 8:00pm"
  And I should see /vouchers (.*) transferred to Chicago - Thurday, April 8, 8:00 PM/i
  And there should be 0 "General" tickets sold for "April 7, 2010, 8:00pm"
  And there should be 1 "General" tickets sold for "April 8, 2010, 8:00pm"


Scenario: box office cannot change walkup if insufficient capacity in other performance

