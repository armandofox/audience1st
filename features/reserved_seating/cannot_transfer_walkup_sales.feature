Feature: cannot edit walkup sales after the fact for reserved seating

  As a box office manager
  To avoid double-booking seats
  I should not be able to transfer walkup vouchers to or from a reserved seating show

Background:

  Given I am logged in as boxoffice
  And a show "Chicago" with the following tickets available:
  | qty | type    | price  | showdate              |
  |   5 | General | $15.00 | April 7, 2012, 8:00pm |
  |   5 | General | $15.00 | April 8, 2012, 8:00pm |
  |   5 | General | $15.00 | April 9, 2012, 8:00pm |
  And the "April 8, 2012, 8pm" performance has reserved seating

Scenario: GA walkup tickets can transfer only to another GA performance

  Given the following walkup tickets have been sold for "April 7, 2012, 8:00pm":
    | qty | type     | payment  |
    |   1 | General  | box_cash |
  And I am on the walkup report page for "April 7, 2012, 8:00pm"
  Then the "Transfer checked vouchers to a different performance:" menu should have options: Monday, Apr 9, 8:00 PM
  And I check "voucher_1"

Scenario: RS walkup tickets can be transferred only to a GA performance  

  Given the following walkup tickets have been sold for "April 8, 2012, 8:00pm":
    | qty | type    | seat | payment  |
    |   1 | General | A1   | box_cash |
  And I am on the walkup report page for "April 8, 2012, 8:00pm"
  Then the "Transfer checked vouchers to a different performance:" menu should have options: Monday, Apr 9, 8:00 PM; Saturday, Apr 7, 8:00 PM
  And I check "voucher_1"
  
Scenario: in a show with only RS performances, no transfers at all

  Given the "April 7, 2012, 8pm" performance has reserved seating
  And   the "April 9, 2012, 8pm" performance has reserved seating
  And I am on the walkup report page for "April 7, 2012, 8:00pm"
  Then I should not see "Transfer checked vouchers to a different performance:"
