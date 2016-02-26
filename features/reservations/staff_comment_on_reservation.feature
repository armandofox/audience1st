@javascript
Feature: staff can add comment to reservation

  As a boxoffice manager
  So that I can make important private notes about a reservation
  I want to add a comment to an existing reservation

Background: customer with existing reservation

  Given I am logged in as boxoffice manager

Scenario: add comment to revenue reservation

  Given customer "Tom Foolery" has the following reservations:
  | show      | showdate         | qty |
  | Hamlet    | Feb 1, 2010, 8pm |   2 |
  | King Lear | Mar 1, 2010, 8pm |   1 |
  When I visit the home page for customer "Tom Foolery"
  And I fill in "comments" with "Will be late" within "#voucher_1"
  And I press "Save" within "#voucher_1"
  And I visit the home page for customer "Tom Foolery"
  Then the "comments" field within "#voucher_1" should contain "Will be late" 

Scenario: add comment to subscriber reservation
