@javascript
Feature: add comps and reserve for a show

  As a box office worker
  So I can comp my best customers
  I want to add comp tickets for a particular performance

Background: logged in as admin and shows are available

  Given I am logged in as boxoffice manager
  And 2 "Comp" comps are available for "Macbeth" on "April 20, 2010, 8pm"

Scenario Outline: add comps to performance

  Given it is currently <time>
  When I visit the add comps page for customer "Armando Fox"
  When I select "Comp (2010)" from "What type:"
  And  I fill in "How many:" with "<number>"
  And  I select "Macbeth - Tuesday, Apr 20, 8:00 PM (2 left)" from "Reserve for:"
  And  I fill in "Optional comments:" with "Courtesy Comp"
  And  I press "Add Vouchers"
  Then customer "Armando Fox" should have an order with comment "Courtesy Comp" containing the following tickets:
  | qty      | type | showdate       |
  | <number> | Comp | Apr 20, 8:00pm |

  Examples:

  | time                 | number |
  | Apr 20, 2010, 8:15pm |      2 |
  | Apr 18, 2010         |      2 |
  | Apr 18, 2010         |      4 |
  | Apr 20, 2010, 8:15pm |      4 |


Scenario: email should be sent if customer_email is checked

  Given it is currently Apr 20, 2010, 8:15pm
  Given customer "Armando Fox" has email "armandoisafox@email.com" and password "pa$$w0rd"
  When I visit the add comps page for customer "Armando Fox"
  When I select "Comp (2010)" from "What type:"
  And  I fill in "How many:" with "2"
  And  I select "Macbeth - Tuesday, Apr 20, 8:00 PM (2 left)" from "Reserve for:"
  And  I fill in "Optional comments:" with "Courtesy Comp"
  And I check "Send Email Confirmation"
  And  I press "Add Vouchers"
  And an email should be sent to customer "Armando Fox" containing "Macbeth"
  
Scenario: email should not be sent if customer_email is unchecked

  Given it is currently Apr 20, 2010, 8:15pm
  Given customer "Armando Fox" has email "armandoisafox@email.com" and password "pa$$w0rd"
  When I visit the add comps page for customer "Armando Fox"
  When I select "Comp (2010)" from "What type:"
  And  I fill in "How many:" with "2"
  And  I select "Macbeth - Tuesday, Apr 20, 8:00 PM (2 left)" from "Reserve for:"
  And  I fill in "Optional comments:" with "Courtesy Comp"
  And I uncheck "Send Email Confirmation"
  And  I press "Add Vouchers"
  And no email should be sent to customer "Armando Fox"

Scenario: checkbox unavailable if customer has no email

  Given it is currently Apr 20, 2010, 8:15pm
  And customer "NoEmail Customer" has no email address
  When I visit the add comps page for customer "NoEmail Customer"
  Then the "Send Email Confirmation" checkbox should be disabled
