Feature: show unfulfilled orders

  As a box office manager
  So that I can send out fulfillments in a timely way and keep customers happy
  I want to see a list of orders requiring mail fulfillment

Background:

  Given subscription vouchers for season 2011
  And the following subscribers exist:
  | customer      | subscriptions | quantity |
  | Joe Mallon    |          2011 |        1 |
  | Patrick Tracy |          2011 |        2 |
  | Star Valdez   |          2011 |        1 |
  And I am logged in as boxoffice manager
  And I visit the unfulfilled orders page

Scenario: list unfulfilled orders

  Then I should see "3 unfulfilled orders (1 unique addresses)"
  And I should see "Joe Mallon"
  And I should see "Patrick Tracy"
  And I should see "Star Valdez"

Scenario: mark some orders as fulfilled  

  When I mark orders 1, 4 as fulfilled
  Then I should see "2 orders marked fulfilled"
  When I visit the unfulfilled orders page
  Then I should see "2 unfulfilled orders (1 unique addresses)"
  And I should see "Patrick Tracy"
  But I should not see the following: "Joe Mallon, Star Valdez"

Scenario: export unfulfilled orders as spreadsheet

  When I follow "Download to Excel"
  Then a CSV file should be downloaded containing:
    | First name | Last name | Email          | Street      | City     | State |   Zip | Sold on                   | Quantity | Product |
    | Joe        | Mallon    | joe1@yahoo.com | 123 Fake St | New York | NY    | 10019 | 2010-01-01 00:00:00 -0800 |        1 |    2011 |
    | Patrick    | Tracy     | joe3@yahoo.com | 123 Fake St | New York | NY    | 10019 | 2010-01-01 00:00:00 -0800 |        2 |    2011 |
    | Star       | Valdez    | joe5@yahoo.com | 123 Fake St | New York | NY    | 10019 | 2010-01-01 00:00:00 -0800 |        1 |    2011 |

