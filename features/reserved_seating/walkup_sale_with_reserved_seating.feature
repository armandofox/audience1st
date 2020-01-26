@javascript
@stubs_successful_credit_card_payment
Feature: walkup sales for reserved seating performance

  As a box office worker
  So that I can sell walkup tickets to a reserved-seating show
  I want to assign seats for walkup sales

Background: show with reserved seating, and nonticket items available for sale

  Given a show "The Nerd" with the following tickets available:
    | qty | type     | price  | showdate           |
    |   3 | General  | $11.00 | March 2, 2010, 8pm |
    |   1 | Discount | $9.00  | March 2, 2010, 8pm |
    |   2 | General  | $11.00 | March 5, 2010, 8pm |
  And the "March 2, 2010, 8pm" performance has reserved seating
  And "Wine" for $7.00 is available at checkin for all performances of "The Nerd"
  And I am logged in as boxoffice
  And I am on the walkup sales page for March 2, 2010, 8pm

Scenario: sell tickets with reserved seats

  When I fill in "General" with "2"
  And I fill in "Discount" with "1"
  And I press "Choose Seats..."
  Then I should see the seatmap
  When I choose seats B1,B2,A1
  Then I should see "A1,B1,B2" in the list of selected seats
  When I complete the walkup sale with credit card
  Then I should see "3 tickets (total $31.00) paid by Credit card. Seats: A1, B1, B2"
  And seats B1,B2 should be occupied for the March 2, 2010, 8pm performance

Scenario: sell tickets as well as nonticket items at a reserved seating show

  When I fill in "General" with "1"
  And I fill in "Wine" with "2"
  And I successfully choose seat B1
  And I complete the walkup sale with credit card
  Then I should see "1 ticket and 2 retail items (total $25.00) paid by Credit card. Seats: B1"

Scenario: sell only retail items at a reserved seating show

  When I fill in "Wine" with "2"
  And I complete the walkup sale with credit card
  Then I should see "2 retail items (total $14.00) paid by Credit card"
  But I should not see "Seats:"

Scenario: sell tickets as well as nonticket items at a general admission show

  When I visit the walkup sales page for March 5, 2010, 8pm
  And I fill in "Wine" with "3"
  And I fill in "General" with "1"
  And I complete the walkup sale with credit card
  Then I should see "1 ticket and 3 retail items (total $32.00) paid by Credit card"
  But I should not see "Seats:"

Scenario: sell only retail items at general admission show

  When I visit the walkup sales page for March 5, 2010, 8pm
  When I fill in "Wine" with "2"
  And I complete the walkup sale with credit card
  Then I should see "2 retail items (total $14.00) paid by Credit card"
