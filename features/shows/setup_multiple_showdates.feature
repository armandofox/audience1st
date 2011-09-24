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
  And I fill in "Advance sales stop" with "60"
  And I fill in "Max advance sales" with "50"
  And I press "Save & Back to List of Shows"
  Then I should be on the list of shows page for "2011"
  Then I should see "5 showdates were successfully added"
  And "Hamlet" should have 5 showdates
  And the following showdates for "Hamlet" should exist:
  | date              | max_sales | sales_cutoff      |
  | 12/23/2011 7:00pm |        50 | 12/23/2011 6:00pm |
  | 12/25/2011 7:00pm |        50 | 12/25/2011 6:00pm |
  | 12/29/2011 7:00pm |        50 | 12/29/2011 6:00pm |
  | 12/30/2011 7:00pm |        50 | 12/30/2011 6:00pm |
  | 1/1/2012 7:00pm   |        50 | 1/1/2012 6:00pm   |

