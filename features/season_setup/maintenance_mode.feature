Feature: turn maintenance mode on and off

  As an admin
  So that I can temporarily restrict access to Audience1st
  I want to turn maintenance mode on or off

Background: maintenance mode is turned on

  Given the boolean setting "Staff Access Only" is "true"

Scenario: staff user can login

  When I login as staff
  Then I should be on the home page

Scenario: regular user cannot login

  Given customer "Tom Foolery" has email "tom@foolery.com" and password "pass"
  When I login as customer "Tom Foolery"
  Then I should see "Audience1st is temporarily unavailable"
  
