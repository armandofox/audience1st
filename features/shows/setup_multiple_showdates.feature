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

  When I select "1/1/2012" as the "Until" date
  And I select "12/23/2011" as the "From" date
  And I select "7:00 pm" as the "At" time
  And I check "Thu"
  And I check "Fri"
  And I check "Sun"
  Then show me the page
  And I fill in "Advance sales stop" with "60"
  And I fill in "Max advance sales" with "50"
  And I press "Save & Back to List of Shows"
  Then "Hamlet" should have 5 showdates
  And the following showdates for "Hamlet" should exist:
  | date | max_sales | sales_cutoff |
