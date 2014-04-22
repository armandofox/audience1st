Feature: admin can list all tickets with explanations

  As an admin
  So I can understand why some tickets are not visible to customers
  I want to see each ticket type with an explanation of why it's not visible

Background: logged in as admin

  Given I am logged in as boxoffice manager
  And today is April 1, 2013
  And a show "Fame" on April 10, 2013

Scenario Outline: Date-related restrictions

  Given 

  Examples:
  | start_sales   | end_sales     | message                                                |
  | 4/2/13 8:00pm | 4/4/13 5:00pm | Tickets of this type not on sale until <4/2/13 8:00pm> |
  | 3/30/13 8pm   | 3/31/13 5pm   | Tickets of this type not sold after <3/31/13 5pm>      |

