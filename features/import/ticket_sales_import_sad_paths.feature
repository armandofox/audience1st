Feature: handling problems with ticket imports

  As a boxoffice manager
  To avoid import-related administrative problems
  I want to see informative messages that let me deal with problematic import situations

Background: logged in as boxoffice

  Given I am logged in as boxoffice
  And I am on the ticket sales import page
  And a show "Company" with the following tickets available:
    | qty | type                           | price  | showdate                |
    |   5 | TodayTix - half off (external) | $19.00 | October 1, 2010, 8:00pm |
    |   5 | TodayTix - half off (external) | $19.00 | October 3, 2010, 3:00pm |

Scenario: import would exceed house capacity

  Given the "October 1, 2010, 8:00pm" performance is truly sold out
  When I upload the "TodayTix" will-call file "two_valid_orders.csv"
  Then I should see "For the Friday, Oct 1, 8:00 PM performance, adding these 3 vouchers to current sales of 200 will exceed the performance's sales cap of 100."
  And I should see "For the Friday, Oct 1, 8:00 PM performance, adding these 3 vouchers to current sales of 200 will exceed the house capacity of 200."
  When I press "Import Orders"
  Then I should see "4 tickets were imported for 2 total customers. None of the customers were already in your list. 2 new customers were created."

Scenario: import would exceed per-ticket-type capacity

  When I upload the "TodayTix" will-call file "too_many_discount_tickets_sold.csv"
  Then I should see "For the Friday, Oct 1, 8:00 PM performance, importing these 7 'TodayTix - half off' vouchers will exceed your intended limit of 5 vouchers of this type"
  When I press "Import Orders"
  Then I should see "8 tickets were imported for 2 total customers. None of the customers were already in your list. 2 new customers were created."

