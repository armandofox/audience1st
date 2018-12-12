@javascript
Feature: staff can delete reservation and comments will stay there

  As a boxoffice manager
  So that I can keep important private notes about a reservation
  I want to keep the comments on a reservation when only some of the tickets are cancelled

Background: customer with existing reservation

  Given I am logged in as boxoffice manager

Scenario: delete tickets to some revenue reservations and keep comments

  Given customer "Tom Foolery" has the following reservations:
  | show      | showdate         | qty |
  | Hamlet    | Feb 1, 2010, 8pm |   10 |
  When I visit the home page for customer "Tom Foolery"
  And I fill in "comments" with "Will be late" within "#voucher_1"
  And I press "✔" within "#voucher_1"
  And I select "5" from "cancelnumber" within "#voucher_1"
  And I press "Cancel" within "#voucher_1"
  And I visit the home page for customer "Tom Foolery"
  Then the "comments" field within "#voucher_6" should contain "Will be late"
