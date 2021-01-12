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
  And I am on the walkup report page for "April 7, 2010, 8:00pm"
  Then I should see "General" within "#box_cash"

Scenario: box office can change walkup to same ticket type for another performance

  When I check "General" within "#box_cash"
  And I select "Thursday, Apr 8, 8:00 PM" from "to_showdate"
  And I press "Transfer"
  Then I should be on the walkup sales page for "April 7, 2010, 8:00pm"
  And I should see "1 vouchers transferred to Chicago - Thursday, Apr 8, 8:00 PM."
  And ticket sales should be as follows:
  | qty | type    | showdate              |
  |   0 | General | April 7, 2010, 8:00pm |
  |   1 | General | April 8, 2010, 8:00pm |

Scenario: transferring doesn't work if you don't check any vouchers

  When I press "Transfer"
  Then I should see "You didn't select any vouchers"
  And ticket sales should be as follows:
  | qty | type    | showdate              |
  |   1 | General | April 7, 2010, 8:00pm |
  |   0 | General | April 8, 2010, 8:00pm |

