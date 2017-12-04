Feature: Delete groups

  As an Box Office Manager
  So that I can manage groups
  I want to be able to delete groups from the groups index

Background:
  Given the groups database isn't seeded
  And a group named "Samsung" exists
Scenario: Groups should be able to be deleted
  Given the groups database isn't seeded
  And a group named "Samsung" exists
  And I am logged in as staff
  And I enter the groups url
  And I follow "Show/Edit" within "#content"
  Then I should not see "Google"
  Then "Google" should not be in the database
