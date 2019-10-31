Feature: import TodayTix sales

  As a boxoffice manager
  To easily merge TodayTix sales into our own sales
  I want to import sales lists from TodayTix

Background: logged in as boxoffice

  Given I am logged in as boxoffice
  And I am on the ticket sales import page
  And a show "Company" with the following tickets available:
    | qty | type                           | price  | showdate                |
    |   5 | TodayTix - half off (external) | $19.00 | October 1, 2010, 8:00pm |
    |   5 | TodayTix - half off (external) | $19.00 | October 3, 2010, 3:00pm |

Scenario: successful import creates new customers; then attempt re-import of same file

  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  Then table "#proposed_import" should include:
    | Name on import | Import to customer       |
    | Moran, Maria   | Will create new customer |
    | Ray, Adrian    | Will create new customer |
  When I press "Import Orders"
  Then the following "TodayTix - half off" tickets should have been imported for "Company":
    | patron      | qty | showdate            |
    | Maria Moran |   3 | Oct 1, 2010, 8:00pm |
    | Adrian Ray  |   1 | Oct 3, 2010, 3:00pm |
  And I should see "4 tickets were imported for 2 total customers. None of the customers were already in your list. 2 new customers were created."
  When I visit the ticket sales import page for the most recent "TodayTix" import
  Then the import for "Moran, Maria" should show "View imported order" 
  And  the import for "Ray, Adrian" should show "View imported order" 
  And  I should not see "Import Orders"
  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  Then I should see "This list was already imported"
  And  I should be on the ticket sales import page
  And customer "Maria Moran" should exist with email "mmoran-rn98@not-hotmail.com"

Scenario: customer unique match on email; verify customer is linked to this import

  Given customer "Maria Moran" exists with email "mmoran-rn98@not-hotmail.com"
  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  Then table "#proposed_import" should include:
    | Name on import | Email on import             | Import to customer       |
    | Moran, Maria   | mmoran-rn98@not-hotmail.com | Maria Moran              |
    | Ray, Adrian    | arrayavalani@not.gmail.com  | Will create new customer |
  When I press "Import Orders"
  Then I should see "4 tickets were imported for 2 total customers. One customer was already in your list. One new customer was created."
  And customer "Maria Moran" should have 3 "TodayTix - half off" tickets for "Company" on Oct 1, 2010, 8:00pm
  And customer "Adrian Ray" should have 1 "TodayTix - half off" tickets for "Company" on Oct 3, 2010, 3:00pm
  When I visit the edit contact info page for customer "Adrian Ray"
  Then I should see "Created by TodayTix import on Jan 1, 2010" within "#adminPrefs"
  And customer "Adrian Ray" should have the following attributes:
    | attribute | value                      |
    | email     | arrayavalani@not.gmail.com |

Scenario: customer non-unique match, boxoffice agent decides whether to import as new or select existing; imported order shows original import name, not matched name; imported customer has email

  Given customer "M Moran" exists with email "moran@example.com"
  And customer "Adrianna Ray" exists with no email
  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  And I select the following options for each import:
    | import_name  | action                                    |
    | Moran, Maria | M Moran (moran@example.com) (123 Fake St) |
    | Ray, Adrian  | Create new customer                       |
  And I press "Import Orders"
  Then I should see "4 tickets were imported for 2 total customers. One customer was already in your list. One new customer was created."
  And customer "M Moran" should have 3 "TodayTix - half off" tickets for "Company" on Oct 1, 2010, 8:00pm
  And customer "Adrian Ray" should have 1 "TodayTix - half off" tickets for "Company" on Oct 3, 2010, 3:00pm
  But customer "Adrianna Ray" should have 0 "TodayTix - half off" tickets for "Company" on Oct 3, 2010, 3:00pm
  And customer "Adrian Ray" should exist with email "arrayavalani@not.gmail.com"
  When I visit the ticket sales import page for the most recent "TodayTix" import
  Then the import for "Moran, Maria" should show "View imported order"

Scenario: import includes comps

  Given a show "Company" with the following tickets available:
    | qty | type                       | price | showdate                |
    |   2 | TodayTix - comp (external) | $0.00 | October 1, 2010, 8:00pm |
  When I upload the "TodayTix" will-call file "includes_comps.csv"
  Then I should see "importing these 3 'TodayTix - comp' vouchers will exceed your intended limit of 2"
  When I press "Import Orders"
  Then customer "Maria Moran" should have 3 "TodayTix - comp" tickets for "Company" on October 1, 2010, 8:00pm
  And customer "Adrian Ray" should have 1 "TodayTix - half off" tickets for "Company" on October 3, 2010, 3:00pm

Scenario: possibly wrong show

  When I upload the "TodayTix" will-call file "wrong_show.csv"
  Then I should see "This list contains an order for 'Wicked' on Sunday, Oct 3, 3:00 PM, but the show name associated with that date is 'Company'."
  But I should not see "This list contains an order for 'Company'"
