Feature: change configuration options

  As an Box Office Manager
  So that Only I can view groups
  I want to see the groups tab and customers to be unable to


Scenario: Admin can see groups tab
  Given I am logged in as administrator
  Then I should see "Groups"

Scenario: Staff can see groups tab
  Given I am logged in as staff
  Then I should see "Groups"

Scenario: Regular user cannot see groups tab
  Given I am logged in as customer "Tom Foolery"
  Then I should not see "Groups"

Scenario: Box Officer should be able to click groups tab and view groups
  Given I am logged in as box office manager
  And I follow "Groups" within "#t_groups_index"
  Then I should see "Listing Groups"

Scenario: Users should not be able to visit the groups url
  Given I am logged in as customer "Tom Foolery"
  And I enter the groups url
  Then I should see "You must have at least Staff privilege for this action."
