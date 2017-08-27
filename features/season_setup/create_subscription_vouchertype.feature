Feature: Create subscription vouchertype

  As a box office manager
  So that I can build up a solid customer base
  I want to offer subscription bundles

Background:

  Given I am logged in as box office manager
  And   the season start date is September 15

Scenario: Create new subscription vouchertype

  When I visit the New Vouchertype page
  And I fill in the "New Voucher Type" fields as follows:
  | field                           | value                        |
  | Type                            | select "Bundle"              |
  | Name                            | NewSub                       |
  | Price                           | 15                           |
  | Display order                   | 8                            |
  | Account Code                    | select "0000 General Fund"   |
  | Availability                    | select "Anyone may purchase" |
  | Season                          | select "2011-2012"           |
  | Mail fulfillment needed         | checked                      |
  | Qualifies buyer as a Subscriber | checked                      |
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
  And I fill in the "Make changes to \"Regular Sub\"" fields as follows:
  | field        | value                         |
  | Availability | select "Box office use only"  |
  | Start sales  | select date "October 1, 2009" |
  | Promo code   | WXYZ                          |
  And I press "Save Changes"
  Then I should see "Vouchertype was successfully updated"
  When I visit the edit page for the "Regular Sub" vouchertype
  Then "October 1, 2009" should be selected as the "Start sales" date
  And "Box office use only" should be selected in the "Availability" menu


