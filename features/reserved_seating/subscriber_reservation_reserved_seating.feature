@javascript
Feature: subscriber can reserve seats

  As a subscriber
  So that I can pick my own seats when using subscriber reservation vouchers
  I want to reserve one or more seats for a particular performance

  Background: show with reserved seating that allows subscriber voucher reservations

  Given a show "The Nerd" with the following tickets available:
    | qty | type     | price  | showdate           |
    |   3 | General  | $11.00 | March 2, 2010, 8pm |
  And the "March 2, 2010, 8pm" performance has reserved seating
  And customer "Tom Foolery" has 3 of 3 open subscriber vouchers for "The Nerd" 
  And I am logged in as customer "Tom Foolery"
  And I am on the home page for customer "Tom Foolery"

  Scenario: reserve subset of my available seats

    When I select "2" from "number"
    And I select "Tuesday, Mar 2, 8:00 PM" from "showdate_id"
    Then I should see the seatmap
    When I choose seats Reserved-A1,Reserved-B1
    And I press "Confirm"
    Then customer "Tom Foolery" should have seats A1,B1 for the Mar 2, 2010, 8pm performance of "The Nerd"
    And customer "Tom Foolery" should have 1 of 3 open subscriber vouchers
