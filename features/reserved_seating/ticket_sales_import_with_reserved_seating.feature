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
    
  Scenario Outline: successful import while assigning seats

    When I confirm seat Reserved-A1 for import customer "Newcustomer, Cynthia"
    And I confirm seats Reserved-A2,Reserved-B1 for import customer "Albrecht, Bob"
    And I press "Import Orders"
    Then seats Reserved-A1,Reserved-A1,Reserved-B1 should be occupied for the Jan 12,2010,8pm performance
    And the Jan 12,2010,8pm performance should have the following seat assignments:
      | name                | seats                    |
      | Bob Albrecht        | Reserved-A2, Reserved-B1 |
      | Cynthia Newcustomer | Reserved-A1              |

  Scenario: if import cancelled, temporarily-assigned seats get released

    When I confirm seat Reserved-A1 for import customer "Newcustomer, Cynthia"
    And I confirm seats Reserved-A2,Reserved-B1 for import customer "Albrecht, Bob"
    And I press "Cancel Import"
    Then seats Reserved-A1,Reserved-A1,Reserved-B1 should be available for the Jan 12,2010,8pm performance

  Scenario: if race condition occurs during seat assignment, error message is clear

    
