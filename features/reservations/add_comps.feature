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

  Scenario: add comps without reserving for a specific showdate

    Given it is currently Apr 20, 2010, 8:15pm
    When I visit the add comps page for customer "Armando Fox"
    When I select "Comp (2010)" from "What type:"
    And I fill in "How many:" with "2"
    And I select "Leave Open" from "Reserve for:"
    And  I press "Add Vouchers"
    Then I should see "Added 2 'Comp' comps and customer can choose the show later"
    And customer "Armando Fox" should have an order with comment "" containing the following tickets:
      | qty | type | showdate |
      |   2 | Comp |          |

  Scenario: add comps that can be left open even if the comp is not currently redeemable for anything

    Given a "NullComp" vouchertype costing $0 for the 2010 season
    When I visit the add comps page for customer "Armando Fox"
    And I select "NullComp (2010)" from "What type:"
    And I fill in "How many:" with "2"
    And I select "Leave Open" from "Reserve for:"
    And I press "Add Vouchers"
    Then I should see "Added 2 'NullComp' comps and customer can choose the show later"
    And customer "Armando Fox" should have an order with comment "" containing the following tickets:
      | qty | type     | showdate |
      |   2 | NullComp |          |
    
  Scenario: email should be sent if customer_email is checked

    Given customer "Armando Fox" exists with email "armandoisafox@gmail.com"
    When I visit the add comps page for customer "Armando Fox"
    When I select "Comp (2010)" from "What type:"
    And  I fill in "How many:" with "2"
    And  I select "Macbeth - Tuesday, Apr 20, 8:00 PM (2 left)" from "Reserve for:"
    And  I fill in "Optional comments:" with "Courtesy Comp"
    And I check "Send Email Confirmation"
    And  I press "Add Vouchers"
    And an email should be sent to customer "Armando Fox" containing "Macbeth"
    
  Scenario: email should not be sent if customer_email is unchecked

    Given customer "Armando Fox" exists with email "armandoisafox@gmail.com"
    When I visit the add comps page for customer "Armando Fox"
    When I select "Comp (2010)" from "What type:"
    And  I fill in "How many:" with "2"
    And  I select "Macbeth - Tuesday, Apr 20, 8:00 PM (2 left)" from "Reserve for:"
    And  I fill in "Optional comments:" with "Courtesy Comp"
    And I uncheck "Send Email Confirmation"
    And  I press "Add Vouchers"
    And no email should be sent to customer "Armando Fox"

  Scenario: checkbox unavailable if customer has no email

    Given customer "NoEmail Customer" has no email address
    When I visit the add comps page for customer "NoEmail Customer"
    Then the "Send Email Confirmation" checkbox should be disabled
