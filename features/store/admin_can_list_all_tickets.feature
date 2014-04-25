Feature: admin can list all tickets with explanations

  As an admin
  So I can understand why some tickets are not visible to customers
  I want to see each ticket type with an explanation of why it's not visible

Background: logged in as admin

  Given I am logged in as boxoffice manager
  And a performance of "Fame" on "April 10, 2013, 8:00pm"
  And a "General" vouchertype costing $10 for the 2013 season
  And today is April 1, 2013

Scenario Outline: Date-related restrictions

  Given sales cutoff at "<end_advance_sales>", with "General" tickets selling from <start_sales> to <end_sales>
  When I visit the store page for "Fame"
  Then I should see "<message>" within the container for "General" tickets

  Examples:
  | end_advance_sales | start_sales | end_sales     | message                                                          |
  | 4/10/13 6pm       | 4/2/13  8pm | 4/4/13 5:00pm | Tickets of this type not on sale until Tuesday, Apr  2,  8:00 PM |
  | 4/10/13 6pm       | 3/30/13 8pm | 3/31/13 5pm   | Tickets of this type not sold after Sunday, Mar 31,  5:00 PM     |
  | 3/31/13 6pm       | 3/29/13 6pm | 3/30/13 5pm   | Advance sales for this performance are closed                    |
  | 4/10/13 6pm       | 3/30/13 6pm | 3/31/13 6pm   |                                                                  |

Scenario Outline: Capacity-related restrictions

  Given there are <per_ticket_limit> "General" tickets and <remaining_seats> total seats available
  When I visit the store page for "Fame"
  Then I should see "<message>" within the container for "General" tickets

  Examples:
  | per_ticket_limit | remaining_seats | message                                     |
  |                3 |               0 | Event is sold out                           |
  |                0 |               3 | No seats remaining for tickets of this type |
  |                3 |               2 | 2 of these tickets remaining                |
  |                3 |               3 | 3 of these tickets remaining                |
  |                  |                 |                                             |


