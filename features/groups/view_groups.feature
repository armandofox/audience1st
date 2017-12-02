Feature: change configuration options

  As an Box Office Manager
  So that Only I can view groups
  I want to see the groups index and customers to be unable to

Scenario: Staff can see group index
  Given I am logged in as staff
  And I enter the groups url
  Then I should see "Listing Group"

Scenario: Users cannot see group index
  Given I am logged in as customer "Tom Foolery"
  And I enter the groups url
  Then I should see "You must have at least Staff privilege for this action."
