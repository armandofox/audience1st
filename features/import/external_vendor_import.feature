Feature: import third party sales

  As a boxoffice manager
  To easily merge external vendor sales into our own sales
  I want to import sales lists from external vendors

Background: logged in as boxoffice

  Given I am logged in as boxoffice
  And I am on the admin:import page
  And a show "Chicago" with the following tickets available:
    | qty | type                | price  | showdate                |
    |  10 | TodayTix - half off | $19.00 | October 1, 2010, 8:00pm |
    |  10 | TodayTix - half off | $19.00 | October 3, 2010, 3:00pm |

Scenario: no tickets from this will-call have been previously imported, no customers known

  When I upload the "TodayTix" will-call file "four_valid_orders.csv"
  Then show me the page
  And I select the following options for each import:
  | import_name         | action              |
  | Moran, Maria        | Create new customer |
  | Song, Bryan         | Create new customer |
  | Ray Avalani, Adrian | Create new customer |
  And I press "Import Orders"
  Then I should not see the message for "import.import_failed"
  Then show me the page
  Then the following "TodayTix - half off" tickets should have been imported for "Chicago":
    | patron             | qty | showdate            |
    | Maria Moran        |   3 | Oct 1, 2010, 8:00pm |
    | Bryan Song         |   2 | Oct 1, 2010, 8:00pm |
    | Adrian Ray Avalani |   1 | Oct 3, 2010, 3:00pm |

Scenario: customer unique match on email

Scenario: customer non-unique match, boxoffice agent selects matching customer

Scenario: customer non-unique match, boxoffice agent decides to import as new

Scenario: some orders have already been imported

Scenario: total number of tickets to import exceeds max sales for date

Scenario: capacity control exceeded on one of the ticket types to import
