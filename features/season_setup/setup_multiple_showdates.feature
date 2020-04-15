Feature: set up multiple showdates at once

  As a harried box office manager
  So that I can save time
  I want to setup multiple showdates with recurring pattern

Background: 

  Given I am logged in as box office manager
  And the seatmap "Default" exists
  And there is a show named "Hamlet" opening "2011-12-20" and closing "2012-01-10"
  And I am on the new showdate page for "Hamlet"

Scenario: set up multiple valid showdates

  When I fill in the "new_showdate" fields as follows:
    | field              | value                                   |
    | show_run_dates     | date range "2012-01-01" to "2011-12-23" |
    | Thu                | checked                                 |
    | Fri                | checked                                 |
    | Sun                | checked                                 |
    | At                 | select time "7:00pm"                    |
    | Advance sales stop | 60                                      |
    | Max advance sales  | 50                                      |
    | Seat map           | select "None (general admission)"       |
    | House capacity     | 20                                      |
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
  And the "2012-01-01 7:00pm" performance should be General Admission

Scenario: set up new showdate with reserved seating

  When I fill in the "new_showdate" fields as follows:
    | field              | value                                   |
    | show_run_dates     | date range "2012-01-01" to "2012-01-03" |
    | At                 | select time "2:00 pm"                   |
    | Advance sales stop | 60                                      |
    | Max advance sales  | 50                                      |
    | Seat map           | select "Default (4)"                    |
    | Sun                | checked                                 |
  And I press "Save & Back to List of Shows"
  Then I should see "One showdate was successfully added"
  And the "2012-01-01 2:00pm" performance should use the "Default" seatmap
  
