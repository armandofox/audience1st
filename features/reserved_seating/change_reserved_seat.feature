Feature: boxoffice can change seat on existing reservation

  As a box office worker
  So that I can upgrade premium customers on demand when better seats are available
  I want to change seats on an existing reservation without having to cancel and rebook it

  Background: existing reservations for a reserved seating performance

  Given the following seat reservations for the March 2, 2010, 8:00pm performance of "Chicago":
    | first  | last    | vouchertype | seats |
    | Harvey | Schmidt | General     | A1,A2 |
  And I am logged in as boxoffice
  And I am on the home page for customer "Harvey Schmidt"
  When I press "Change..."
  Then I should see the seatmap

  Scenario: successfully change multiple seats
    
    
    
  
  Scenario: cannot change to a seat that has become occupied

    Given the following seat reservations for the March 2, 2010, 8:00pm performance of "Chicago":
      | first  | last    | vouchertype | seats |
      | Tom    | Jones   | General     | B1    |
