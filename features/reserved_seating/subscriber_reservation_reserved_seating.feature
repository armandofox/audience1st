Feature: subscriber can reserve seats

  As a subscriber
  So that I can pick my own seats when using subscriber reservation vouchers
  I want to reserve one or more seats for a particular performance

  Background: show with reserved seating that allows subscriber voucher reservations

  Given a show "The Nerd" with the following tickets available:
    | qty | type     | price  | showdate           |
    |   3 | General  | $11.00 | March 2, 2010, 8pm |
  And the "March 2, 2010, 8pm" performance has reserved seating
  And customer "Tom Foolery" has 2 of 2 open subscriber vouchers for "The Nerd" 
  And I am logged in as customer "Tom Foolery"
  And I am on the home page for customer "Tom Foolery"

  Scenario: reserve single seat



  Scenario: reserve multiple seats

  Scenario: cancel existing reservation with reserved seats

    
