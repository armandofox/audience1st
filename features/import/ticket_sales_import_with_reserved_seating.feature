@suspended
@javascript
Feature: import third party ticket sales for a reserved seating performance

  As a boxoffice manager
  To allow external vendor sales for reserved seating shows
  I want to assign seats at import time for external vendor sales lists

  Background: logged in as boxoffice, ready to import for a reserved seating performance

    Given I am logged in as boxoffice
    And I am on the ticket sales import page
    And a show "Hand to God" with the following tickets available:
      | qty | type                          | price  | showdate                 |
      |   2 | Goldstar - General (external) | $15.00 | January 12, 2010, 8:00pm |
      |   2 | Goldstar - Comp (external)    | $0.00  | January 12, 2010, 8:00pm |
    And the "January 12, 2010, 8:00pm" performance has reserved seating
    And I upload a "Goldstar" will-call file for Jan 12, 2010, 8pm with the following orders:
      | name                | qty | type               |
      | Bob Albrecht        |   2 | Goldstar - General |
      | Cynthia Newcustomer |   1 | Goldstar - Comp    |
    
  Scenario: successful import while assigning seats

    And I confirm seat "Reserved-A1" for import customer "Newcustomer, Cynthia"
    When I confirm seats "Reserved-A2,Reserved-B1" for import customer "Albrecht, Bob"
    Then the "Import Orders" button should be enabled
    When I press "Import Orders"
    Then seats A1,A2,B1 should be occupied for the Jan 12,2010,8pm performance
    And the Jan 12,2010,8pm performance should have the following seat assignments:
      | name                | seats |
      | Bob Albrecht        | A2,B1 |
      | Cynthia Newcustomer | A1    |

  Scenario: if import cancelled, temporarily-assigned seats get released

    When I confirm seat "Reserved-A1" for import customer "Newcustomer, Cynthia"
    And I confirm seats "Reserved-A2,Reserved-B1" for import customer "Albrecht, Bob"
    And I cancel the ticket sales import
    Then seats A1,A2,B1 should be available for the Jan 12,2010,8pm performance

  Scenario: if patron has seats assigned and then you re-assign, current seats show as selected

  Scenario: Cancel Seat Selection releases patron's seats, even if they were previously assigned

  Scenario: if race condition occurs during seat assignment, error message is clear and seats are not assigned

    When I fail to confirm seat "Reserved-A1" for import customer "Newcustomer, Cynthia"
    Then the "Import Orders" button should be disabled
    And import customer "Newcustomer, Cynthia" should not have any seat assignment
