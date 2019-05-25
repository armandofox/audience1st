Feature: import third party sales

  As a boxoffice manager
  To easily merge external vendor sales into our own sales
  I want to import sales lists from external vendors

Background: logged in as boxoffice

  Given I am logged in as boxoffice
  And I am on the admin:import page
  And a show "Chicago" with the following tickets available:
    | qty | type                | price  | showdate                |
    |  10 | TodayTix - half off | $13.00 | October 1, 2010, 7:00pm |
    |  10 | TodayTix - half off | $13.00 | October 3, 2010, 3:00pm |

Scenario: no tickets from this will-call have been previously imported

  When I upload the "TodayTix" will-call file "four_valid_orders.csv"
  Then show me the page

Scenario: some orders have already been imported

Scenario: total number of tickets to import exceeds max sales for date

Scenario: capacity control exceeded on one of the ticket types to import
