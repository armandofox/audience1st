Feature: Create subscription vouchertype

  As a box office manager
  So that I can build up a solid customer base
  I want to offer subscription bundles

Background:

  Given I am logged in as box office manager

Scenario: Create new subscription vouchertype

  When I visit the New Vouchertype page
  And I select "Bundle" from "Type"
  And I fill in "Name" with "NewSub"
  And I fill in "Price" with "15"
  And I fill in "Account Code" with "9999"
  And I select "Anyone may purchase" from "Availability"
  And I select "2011" from "Season"
  And I check "Mail fulfillment needed"
  And I check "Qualifies buyer as a Subscriber"
  And I press "Create"
  Then I should see "Please specify bundle quantities now"
  And a Vouchertype with name "NewSub" should exist
  And it should have a price of 15
  And it should have a season of 2011
  And it should be a Bundle voucher
