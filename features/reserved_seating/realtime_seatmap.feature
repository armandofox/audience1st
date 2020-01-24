@javascript
Feature: show "real time" seatmap

  As a box office worker
  So that I can quickly see which seats are still available tonight
  I want to display a "real time" seat map

Background: show with some reserved seating dates

    Given a show "The Nerd" with the following tickets available:
    | qty | type     | price  | showdate           |
    |   3 | General  | $11.00 | March 2, 2010, 8pm |
    |   1 | Discount | $9.00  | March 3, 2010, 8pm |
  And the "March 2, 2010, 8pm" performance has reserved seating
  And I am logged in as boxoffice

Scenario: display real time seatmap for reserved seating performance

  Given I am on the walkup sales page for March 2, 2010, 8pm
  When I follow "Seat Map"
  Then I should see the seatmap

Scenario: general admission show should not allow viewing seatmap

  Given I am on the walkup sales page for March 3, 2010, 8pm
  Then I should not see "Seat Map"

