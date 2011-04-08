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
  |   2 | General  | box_cash |
  And I am on the walkup sales report for "April 7, 2010, 8:00pm"

Scenario: box office can change walkup to same ticket type for another performance

Scenario: box office cannot change walkup if insufficient capacity in other performance

