Feature: change configuration options

  As an admin
  So that I can tailor Audience1st to my venue
  I want to see and edit the configuration options

Background: logged in as admin
  
  Given I am logged in as administrator
  And I visit the admin:settings page

Scenario: successfully change options

  When I fill in all valid options
  And I press "Update Settings"
  Then I should be on the admin:settings page
  And I should see "Update successful"

Scenario: some options are invalid

  When I fill in all valid options
  And I fill in "Venue" with ""
  And I press "Update Settings"
  Then I should be on the admin:settings page
  And I should see "Venue can't be blank"
