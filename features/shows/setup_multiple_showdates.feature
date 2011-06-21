Feature: set up multiple showdates at once

  As a harried box office manager
  So that I can save time
  I want to setup multiple showdates with recurring pattern

Background: 

  Given I am logged in as box office manager
  And there is a show named "Hamlet" opening "12/20/2011" and closing "1/10/2012"
  And I am on the new showdate page for "Hamlet"
  Then "12/20/2011" should be selected as the "From" date
  And "1/10/2012" should be selected as the "Until" date

Scenario: set up multiple valid showdates

  
