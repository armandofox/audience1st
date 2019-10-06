Feature: Create subscription vouchertype

  As a box office manager
  So that I can offer various price points
  I want to easily create and edit different voucher types

Background:

  Given I am logged in as box office manager
  And   the season start date is September 15

Scenario: Create new revenue vouchertype, then clone it

  When I visit the New Vouchertype page
  And I fill in the "New Voucher Type" fields as follows:
    | field                 | value                        |
    | Type                  | select "Comp"                |
    | Name                  | Cast Comp                    |
    | Display order         | 8                            |
    | Availability          | select "Box office use only" |
    | Season                | select "2011-2012"           |
    | Walkup sales allowed  | checked                      |
  And I press "Create"
  Then I should be on the vouchertypes page
  And I should see a row "|8|Cast Comp|0.00|||Box office use only|||Yes" within "table[@id='vouchertypes']"
  When I try to clone the "Cast Comp" vouchertype
  And I fill in "Name" with "Goldstar Comp"
  And I fill in "Display order" with "6"
  And I select "Sold by external reseller" from "Availability"
  And I uncheck "Walkup sales allowed"
  And I press "Create"
  Then I should be on the vouchertypes page
  And I should see a row "|6|Goldstar Comp|0.00|||Sold by external reseller|||^$" within "table[@id='vouchertypes']"
  And I should see a row "|8|Cast Comp|0.00|||Box office use only|||Yes" within "table[@id='vouchertypes']"

