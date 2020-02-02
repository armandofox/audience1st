@javascript
Feature: import third party ticket sales for a reserved seating performance

  As a boxoffice manager
  To allow Goldstar sales for reserved seating shows
  I want to assign seats at import time for Goldstar sales lists

Background: logged in as boxoffice ready to import for a reserved seating performance

  Given I am logged in as boxoffice
  And I am on the ticket sales import page
  And a show "Hand to God" with the following tickets available:
    | qty | type                          | price  | showdate                 |
    |   2 | Goldstar - General (external) | $15.00 | January 12, 2010, 8:00pm |
    |   2 | Goldstar - Comp (external)    | $0.00  | January 12, 2010, 8:00pm |
  And the "January 12, 2010, 8:00pm" performance has reserved seating

Scenario: successful import while assigning seats

  When I upload the "Goldstar" will-call file "2010-01-12-HandToGod-reserved-seating.json"
  Then show me the page
  
