Feature: import third party sales

  As a boxoffice manager
  To easily merge external vendor sales into our own sales
  I want to import sales lists from external vendors

Background: logged in as boxoffice

  Given I am logged in as boxoffice
  And I am on the ticket sales import page
  And a show "Chicago" with the following tickets available:
    | qty | type                | price  | showdate                |
    |  10 | TodayTix - half off | $19.00 | October 1, 2010, 8:00pm |
    |  10 | TodayTix - half off | $19.00 | October 3, 2010, 3:00pm |

Scenario: no tickets from this will-call have been previously imported, no customers known

  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  Then table "#proposed_import" should include:
  | Name on import | Import to customer       |
  | Moran, Maria   | Will create new customer |
  | Ray, Adrian    | Will create new customer |
  When I press "Import Orders"
  Then the following "TodayTix - half off" tickets should have been imported for "Chicago":
    | patron      | qty | showdate            |
    | Maria Moran |   3 | Oct 1, 2010, 8:00pm |
    | Adrian Ray  |   1 | Oct 3, 2010, 3:00pm |
  And I should see "4 tickets added for 2 new customers and 0 existing customers"
  When I visit the ticket sales import page for the most recent "TodayTix" import
  Then the import for "Moran, Maria" should show "Previously imported" 
  And  the import for "Ray, Adrian" should show "Previously imported" 
  And  I should not see "Import Orders"
  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  Then the import for "Moran, Maria" should show "Previously imported" 
  And  the import for "Ray, Adrian" should show "Previously imported" 
  And  I should not see "Import Orders"

Scenario: customer unique match on email

  Given customer "Maria Moran" exists with email "mmoranrn98@not.hotmail.com"
  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  Then table "#proposed_import" should include:
    | Name on import | Email on import            | Import to customer       |
    | Moran, Maria   | mmoranrn98@not.hotmail.com | Maria Moran              |
    | Ray, Adrian    | arrayavalani@not.gmail.com | Will create new customer |
  When I press "Import Orders"
  Then I should see "4 tickets added for 1 new customers and 1 existing customers"
  And customer "Maria Moran" should have 3 "TodayTix - half off" tickets for "Chicago" on Oct 1, 2010, 8:00pm
  And customer "Adrian Ray" should have 1 "TodayTix - half off" tickets for "Chicago" on Oct 3, 2010, 3:00pm

Scenario: customer non-unique match, boxoffice agent decides whether to import as new or select existing

  Given customer "M Moran" exists with email "moran@example.com"
  And customer "Adrianna Ray" exists with no email
  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  And I select the following options for each import:
  | import_name  | action                                    |
  | Moran, Maria | M Moran (moran@example.com) (123 Fake St) |
  | Ray, Adrian  | Create new customer                       |
  And I press "Import Orders"
  Then I should see "4 tickets added for 1 new customers and 1 existing customers"
  And customer "M Moran" should have 3 "TodayTix - half off" tickets for "Chicago" on Oct 1, 2010, 8:00pm
  And customer "Adrian Ray" should have 1 "TodayTix - half off" tickets for "Chicago" on Oct 3, 2010, 3:00pm
  But customer "Adrianna Ray" should have 0 "TodayTix - half off" tickets for "Chicago" on Oct 3, 2010, 3:00pm
  
Scenario: customer non-unique match, boxoffice agent decides to import as new

Scenario: total number of tickets to import exceeds max sales for date

Scenario: capacity control exceeded on one of the ticket types to import
