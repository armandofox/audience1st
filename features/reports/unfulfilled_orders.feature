Feature: show unfulfilled orders

  As a box office manager
  So that I can send out fulfillments in a timely way and keep customers happy
  I want to see a list of orders requiring mail fulfillment

Background:

  Given the following customers exist:
  | first_name | last_name | email             | street         | city    | state |   zip |
  | Joe        | Mallon    | joe@joescafe.com  | 1409 High St   | Alameda | CA    | 94501 |
  | Patrick    | Tracy     | pt@altarena.org   | 1409 High St   | Alameda | CA    | 94501 |
  | Star       | Valdez    | star@altarena.org | Jack London Sq | Oakland | CA    | 94611 |
  And subscription vouchers for season 2011
  And the following subscribers exist:
  | customer      | subscriptions | quantity |
  | Joe Mallon    |          2011 |        1 |
  | Patrick Tracy |          2011 |        2 |
  | Star Valdez   |          2011 |        1 |
  And I am logged in as boxoffice manager
  And I visit the unfulfilled orders page
  
Scenario: list unfulfilled orders

  Then I should see "4 unfulfilled orders (2 unique addresses)"
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
    | First name | Last name | Email             | Street         | City    | State |   Zip | Sold on                   | Quantity | Product |
    | Joe        | Mallon    | joe@joescafe.com  | 1409 High St   | Alameda | CA    | 94501 | 2010-01-01 00:00:00 -0800 |        1 |    2011 |
    | Patrick    | Tracy     | pt@altarena.org   | 1409 High St   | Alameda | CA    | 94501 | 2010-01-01 00:00:00 -0800 |        2 |    2011 |
    | Star       | Valdez    | star@altarena.org | Jack London Sq | Oakland | CA    | 94611 | 2010-01-01 00:00:00 -0800 |        1 |    2011 |

