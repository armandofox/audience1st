Feature: display comments in door list

  As a box officer
  So that I can see customers' comments when they check in 
  I want to generate a printable door list that has customers' item level comments

Background: customer is logged in

  Given I am logged in as customer "Tom Foolery" 

Scenario: Doorlist correctly reflects comments

  Given my cart contains the following tickets:
    | qty | type    | show    | price | showdate         |
    |   2 | General | Chicago | 10.00 | Apr 2, 2010, 8pm |
  And I am on the checkout page
  Then I should see "Is someone other than the purchaser picking up the tickets?"
  When I fill in "pickup" with "Jason Gray"
  And the order is placed successfully

  Then I am logged in as boxoffice manager
  When I visit the home page for customer "Tom Foolery"
  Then the "comments" field within "#voucher_1" should equal " - Pickup by: Jason Gray"
  And I fill in "comments" with "2 wheelchairs" within "#voucher_1"
  And I press "✔" within "#voucher_1"
  And I visit the home page for customer "Tom Foolery"
  Then the "comments" field within "#voucher_1" should equal "2 wheelchairs"
  Then customer "Tom Foolery" should have the following comments:
  | showdate         | comment       |
  | Apr 2, 2010, 8pm | 2 wheelchairs |

  Given a performance of "Chicago" on April 2, 2010, 8:00pm
  And customer Tom Foolery has 2 "General" tickets
  When I go to the door list page for April 2, 2010, 8:00pm
  Then I should see the following details in door list:
  | Last    | First | Type    | Qty | Notes         |
  | Foolery | Tom   | General |   2 | 2 wheelchairs |

  And I should not see " - Pickup by: Jason Gray;2 wheelchairs"

  When I visit the home page for customer "Tom Foolery"
  And I select "2" from "cancelnumber" within "#voucher_1"
  And I press "Cancel" within "#voucher_1"
  When I go to the door list page for April 2, 2010, 8:00pm
  Then I should not see "2 wheelchairs"

