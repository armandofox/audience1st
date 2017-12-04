Feature: Show/edit groups

  As an Box Office Manager
  So that I can manage groups
  I want to be able to delete groups from the groups index

Background:
  Given the groups database isn't seeded
  And a company named "Samsung" exists
  And I am logged in as staff
  And I enter the groups url

Scenario: Clicking the group brings you to its edit page
  Given I follow "Show/Edit" within "#content"
  Then I should see "Group Information"
  Then I should see "Editing Samsung"
  Then I should see "Group Name"
  Then the form should contain "Samsung"

Scenario: Changing form info changes the group
  Given I enter the groups page for "Samsung"
  And I enter "1 Main Street" into "#address_line_1"
  And I submit the form by pressing "Edit Group"
  Then I should see "Listing"
  And I enter the groups page for "Samsung"
  Then the form should contain "1 Main Street"
  Then group named "Samsung" should have "1 Main Street" for "address_line_1"
