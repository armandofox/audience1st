@javascript
Feature: purchase tickets for a performance with reserved seating

  As a patron
  So that I can get the best seats
  I want to buy tickets for a performance with reserved seating:

Background: performance with reserved seating

  Given a show "The Nerd" with the following tickets available:
    | qty | type     | price  | showdate           |
    |   3 | General  | $11.00 | March 2, 2010, 8pm |
    |   1 | Discount | $9.00  | March 2, 2010, 8pm |
  And the "March 2, 2010, 8pm" performance has reserved seating

Scenario: purchase tickets with reserved seating

  Given I am logged in as customer "Tom Foolery"
  When I go to the store page for the show "The Nerd"
  And I select "1" from "General - $11.00"
  And I select "1" from "Discount - $9.00"
  And I press "Choose Seats..."
  And I choose seats B1,B2
  And I press "Continue to Billing Information"
  Then the cart should show the following items:
    | description             | seats | price |
    | Tuesday, Mar 2, 8:00 PM | B1    | 11.00 |
    | Tuesday, Mar 2, 8:00 PM | B2    | 9.00  |

Scenario: when admin purchases tickets, nonticket items shouldn't require seats

  Given I am logged in as boxoffice
  And "Wine" for $7.00 is available for all performances of "The Nerd"
  When I go to the store page for the show "The Nerd"
  And I fill in "General - $11.00" with "2"
  And I fill in "Wine - $7.00" with "1"
  And I press "Choose Seats..."
  And I choose seats B1,B2
  When I press "Continue to Billing Information"
  Then the cart should show the following items:
    | description             | seats | price |
    | Tuesday, Mar 2, 8:00 PM | B1    | 11.00 |
    | Tuesday, Mar 2, 8:00 PM | B2    | 11.00 |
    | Wine                    |       |  7.00 |
  
  
