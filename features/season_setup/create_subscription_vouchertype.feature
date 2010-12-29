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
  Then I should be redirected to the Vouchertypes page
  And I should see "Vouchertype successfully created"

