Feature: display comments in door list

  As a box officer
  So that I can see customers' comments when they check in 
  I want to generate a printable door list that has customers' item level comments

Background: customer is logged in

  Given I am logged in as customer "Tom Foolery" 

Scenario: Doorlist correctly reflects comments

  Given a performance of "Chicago" on April 2, 2010, 8:00pm
  Given my cart contains the following tickets:
    | qty | type    | show    | price | showdate         |
    |   2 | General | Chicago | 10.00 | Apr 2, 2010, 8pm |
  And I am on the checkout page
  And I fill in "pickup" with "Jason Gray"
  And the order is placed successfully
  And I am logged in as boxoffice manager
  And I visit the home page for customer "Tom Foolery"
  And I fill in "comments" with "2 wheelchairs" within "#voucher_1"
  And I press "✔" within "#voucher_1"
  And I visit the home page for customer "Tom Foolery"
  And customer Tom Foolery has 2 "General" tickets
  When I go to the door list page for April 2, 2010, 8:00pm
  Then I should see the following details in door list:
  | Last    | First | Type    | Qty | Notes         |
  | Foolery | Tom   | General |   2 | 2 wheelchairs |

Scenario: Doorlist shouldn't contain the comments when they are deleted

  Given a performance of "Chicago" on April 2, 2010, 8:00pm
  Given my cart contains the following tickets:
    | qty | type    | show    | price | showdate         |
    |   2 | General | Chicago | 10.00 | Apr 2, 2010, 8pm |
  And I am on the checkout page
  And I fill in "pickup" with "Jason Gray"
  And the order is placed successfully
  And I am logged in as boxoffice manager
  And I visit the home page for customer "Tom Foolery"
  And I fill in "comments" with "2 wheelchairs" within "#voucher_1"
  And I press "✔" within "#voucher_1"
  And I visit the home page for customer "Tom Foolery"
  And I select "2" from "cancelnumber" within "#voucher_1"
  And I press "Cancel" within "#voucher_1"
  When I go to the door list page for April 2, 2010, 8:00pm
  Then I should not see "2 wheelchairs"