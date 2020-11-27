@time
Feature: admin can list all tickets with explanations

  As an admin
  So I can understand why some tickets are not visible to customers
  I want to see each ticket type with an explanation of why it's not visible

Background: logged in as admin

  Given today is April 1, 2011
  Given I am logged in as boxoffice manager
  And a performance of "Fame" on "April 10, 2011, 8:00pm"
  And a "General" vouchertype costing $10 for the 2011 season

Scenario Outline: Date-related restrictions

  Given "General" tickets selling from <start_sales> to <end_sales>
  When I visit the store page for the show "Fame"
  Then I should see "<message>" within the container for "General" tickets

  Examples:
  | start_sales    | end_sales         | message                                                         |
  | 2011-04-02 8pm | 2011-04-04 5:00pm | Tickets of this type not on sale until Saturday, Apr 2, 8:00 PM |
  | 2011-03-30 8pm | 2011-03-31 5pm    | Tickets of this type not sold after Thursday, Mar 31, 5:00 PM   |
  | 2011-03-29 6pm | 2011-03-30 5pm    | Tickets of this type not sold after Wednesday, Mar 30, 5:00 PM  |

Scenario Outline: Capacity-related restrictions

  Given there are <per_ticket_limit> "General" tickets and <remaining_seats> total seats available
  When I visit the store page for the show "Fame"
  Then I should see "<message>" within the container for "General" tickets

  Examples:
  | per_ticket_limit | remaining_seats | message                                     |
  |                3 |               0 | Event is sold out                           |
  |                0 |               3 | No seats remaining for tickets of this type |
  |                3 |               2 | 2 remaining                                 |
  |                3 |               3 | 3 remaining                                 |


