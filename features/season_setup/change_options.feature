Feature: change configuration options

  As an admin
  So that I can tailor Audience1st to my venue
  I want to see and edit the configuration options

Background: logged in as admin
  
  Given I am logged in as administrator
  And I visit the settings page

Scenario: successfully change options

  When I fill in all valid options
