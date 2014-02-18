Feature: Create subscription vouchertype

  As a box office manager
  So that I can build up a solid customer base
  I want to offer subscription bundles

Background:

  Given I am logged in as box office manager
  And   the season start date is September 15

Scenario: Create new subscription vouchertype

  When I visit the New Vouchertype page
  And I select "Bundle" from "Type"
  And I fill in "Name" with "NewSub"
  And I fill in "Price" with "15"
  And I fill in "Display order" with "8"
  And I select "9999 General Fund" from "Account Code"
  And I select "Anyone may purchase" from "Availability"
  And I select "2011-2012" from "Season"
  And I check "Mail fulfillment needed"
  And I check "Qualifies buyer as a Subscriber"
  And I press "Create"
  Then I should see "Please specify bundle quantities now"
  And a Vouchertype with name "NewSub" should exist
  And it should have a price of 15
  And it should have a season of 2011
  And it should be a Bundle voucher
  When I visit the edit page for the "NewSub" vouchertype
  Then "September 15, 2011" should be selected as the "Start sales" date
  And  "September 14, 2012" should be selected as the "End sales" date

Scenario: Edit existing subscription vouchertype

  Given a "Regular Sub" subscription available to anyone for $50.00
  When I visit the edit page for the "Regular Sub" vouchertype
  When I select "Box office use only" from "Availability"
  And I select "December 1, 2011" as the "Start sales" date
  And I fill in "Promo code" with "WXYZ"
  And I press "Save Changes"
  Then I should see "Vouchertype was successfully updated"
  When I visit the edit page for the "Regular Sub" vouchertype
  Then show me the page
  Then "December 1, 2011" should be selected as the "Start sales" date
  And "Box office use only" should be selected in the "Availability" menu


