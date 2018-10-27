Feature: set up multiple showdates at once

  As a harried box office manager
  So that I can save time
  I want to setup multiple showdates with recurring pattern

Background: 

  Given I am logged in as box office manager
  And there is a show named "Hamlet" opening "2011-12-20" and closing "2012-01-10"
  And I am on the new showdate page for "Hamlet"

Scenario: set up multiple valid showdates

  When I select "2012-01-01 to 2011-12-23" as the "show_run_dates" date range
  And I check "Thu"
  And I check "Fri"
  And I check "Sun"
  And I select "7:00 pm" as the "At" time
  And I fill in "Advance sales stop" with "60"
  And I fill in "Max advance sales" with "50"
  And I press "Save & Back to List of Shows"
  Then I should see "5 showdates were successfully added"
  And "Hamlet" should have 5 showdates
  And the following showdates for "Hamlet" should exist:
  | date              | max_sales | sales_cutoff      |
  | 2011-12-23 7:00pm |        50 | 2011-12-23 6:00pm |
  | 2011-12-25 7:00pm |        50 | 2011-12-25 6:00pm |
  | 2011-12-29 7:00pm |        50 | 2011-12-29 6:00pm |
  | 2011-12-30 7:00pm |        50 | 2011-12-30 6:00pm |
  | 2012-01-01 7:00pm |        50 | 2012-01-01 6:00pm |

