Feature: Create subscription vouchertype

  As a box office manager
  So that I can build up a solid customer base
  I want to offer subscription bundles

Background:

  Given I am logged in as box office manager

Scenario: Create new subscription vouchertype

  When I visit the New Vouchertype page
  And I fill in "<field>" with "<value>"
  And I select "<choice>" from "<menu>"
  And I select "Bundle" from "Type"
  And I select "Anyone may purchase" from "Availability"
  And I select "2011" from "Season"
  And I check "Mail fulfillment needed"
  And I check "Qualifies buyer as a Subscriber"
  And I press "Create"

  Examples:
    | field                 | value           |
    | Name                  | NewSub          |
    | Price                 | 15              |
    | Account Code          | 9999            |
    | Comments/description  | My new sub      |
