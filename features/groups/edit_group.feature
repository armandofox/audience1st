Feature: Show/edit groups

  As an Box Office Manager
  So that I can manage groups
  I want to be able to delete groups from the groups index

Background:
  Given the groups database isn't seeded
  And a group named "Samsung" exists
  And I am logged in as staff
  And I enter the groups url

Scenario: Clicking the group brings you to its edit page
  Given I follow "Show/Edit" within "#content"
  Then I should see "Group Information"
  Then I should see "Editing Samsung"
  Then the form should contain "Samsung" within "Group Name"

Scenario: Changing form info changes the group
  Given I enter the groups page for "Samsung"
  And I fill in "Group Name" with "1 Main Street"
  And I submit the form by pressing "Edit Group"
  Then I should see "Listing"
  And I enter the groups page for "Samsung"
