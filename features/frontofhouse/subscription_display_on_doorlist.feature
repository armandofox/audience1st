@javascript
Feature: subscriber can make subscriber reservations and staff can change comments 

  As a subscriber
  So that I can conveniently enjoy subscription benefits
  I want to make subscriber reservations online

Background: show with at least one available performance

  Given there is a show named "Hairspray" with showdates:
  | date       | tickets_sold |
  | May 3, 8pm |            0 |
  And customer "Tom Foolery" has 2 of 2 open subscriber vouchers for "Hairspray" 
  And I am logged in as customer "Tom Foolery"
  And I am on the home page for customer "Tom Foolery"

Scenario: Subscription tickets have correct comments

  When I select "2" from "number"
  And I select "Monday, May 3, 8:00 PM" from "showdate_id"
  And I fill in "comments" with "No stairs please"
  And I press "Confirm"
  Then customer "Tom Foolery" should have 2 "Hairspray (Subscriber)" tickets for "Hairspray" on May 3, 8pm

  Given I am logged in as boxoffice manager

  When I visit the home page for customer "Tom Foolery"
  And I fill in "comments" with "2 wheelchairs needed" within "#voucher_1"
  And I press "✔" within "#voucher_1"
  And I visit the home page for customer "Tom Foolery"
  Then the "comments" field within "#voucher_1" should equal "2 wheelchairs needed"
  Then customer "Tom Foolery" should have the following comments:
  | showdate         | comment      |
  | May 3, 2010, 8pm | 2 wheelchairs needed |

  When I go to the door list page for May 3, 2010, 8:00pm
  Then I should see the following details in door list: 
  | Last  | First | Type | Qty | Notes |
  | Foolery | Tom | General | 2 | 2 wheelchairs needed |
  Then I should not see "No stairs please"

  When I visit the home page for customer "Tom Foolery"
  And I select "2" from "cancelnumber" within "#voucher_1"
  And I press "Cancel" within "#voucher_1"
  When I go to the door list page for May 3, 2010, 8:00pm
  Then I should not see "2 wheelchairs needed"
