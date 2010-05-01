Feature: set up new show
  
  As the Box Office Manager
  So that I can sell tickets for a show
  I want to setup the new show

Background:

  Given I am logged in as a box office manager
  And there is no show named "Chicago"

Scenario: Setup new show
  When I go to the New Show page
  And I specify a show "Chicago" playing from "1.week.from_now" until "1.month.from_now" with capacity "100" to be listed starting "Time.now"
  And I press "Create"
  Then I should be on the Show Details page for "Chicago"

