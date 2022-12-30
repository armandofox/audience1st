@javascript
Feature: display redeemed tickets' updated comments on door list

  As a box officer
  I want to see up-to-date comments of redeemed tickets on the door list 

Background: customer's redeemed tickets' comments for the show "Hairspray" are updated by the staff

  Given there is a show named "Hairspray" with showdates:
  | date       | tickets_sold |
  | May 3, 8pm |            0 |
  And customer "Tom Foolery" has 2 of 2 open subscriber vouchers for "Hairspray" 
  And I am logged in as customer "Tom Foolery"
  And I am on the home page for customer "Tom Foolery"
  When I select "2" from "number"
  And I select "Monday, May 3, 8:00 PM" from "showdate_id"
  And I fill in "comments" with "No stairs please"
  And I press "Confirm"
  And I am logged in as boxoffice manager
  And I visit the home page for customer "Tom Foolery"
  And I update the comment for "#voucher_1" with "2 wheelchairs needed"

Scenario: door list correctly reflects updated comments of redeemed ticekts 

  And I visit the home page for customer "Tom Foolery"
  When I go to the door list page for May 3, 2010, 8:00pm
  Then I should not see "No stairs please"
  Then I should see the following details in door list: 
  | Last    | First | Type    | Qty | Notes |
  | Foolery |   Tom | General | 2   | 2 wheelchairs needed |

Scenario: door list shouldn't contain the comments from deleted redeemed ticekts 

  When I visit the home page for customer "Tom Foolery"
  And I cancel 2 "#voucher_1" reservations
  And I go to the door list page for May 3, 2010, 8:00pm
  Then I should not see "2 wheelchairs needed"
