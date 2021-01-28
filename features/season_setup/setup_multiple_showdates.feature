Feature: set up multiple showdates at once

  As a harried box office manager
  So that I can save time
  I want to setup multiple showdates with recurring pattern

  Background: 

    Given I am logged in as box office manager
    And the seatmap "Default" exists
    And there is a show named "Hamlet"
    And I am on the new showdate page for "Hamlet"

  Scenario: set up multiple valid showdates

    When I fill in the "new_showdate" fields as follows:
      | field             | value                                   |
      | show_run_dates    | date range "2010-01-01" to "2010-01-13" |
      | Thu               | checked                                 |
      | Fri               | checked                                 |
      | Sun               | checked                                 |
      | At                | select time "7:00pm"                    |
      | Max advance sales | 40                                      |
      | Seat map          | select "None (general admission)"       |
      | House capacity    | 50                                      |
    And I press "Save & Back to List of Shows"
    Then I should see "5 performances were successfully added"
    And "Hamlet" should have 5 showdates
    And the following showdates for "Hamlet" should exist:
      | date              | max_sales | sales_cutoff      |
      | 2010-01-01 7:00pm |       40  | 2010-01-01 6:00pm |
      | 2010-01-03 7:00pm |       40  | 2010-01-03 6:00pm |
      | 2010-01-07 7:00pm |       40  | 2010-01-07 6:00pm |
      | 2010-01-08 7:00pm |       40  | 2010-01-08 6:00pm |
      | 2010-01-10 7:00pm |       40  | 2010-01-10 6:00pm |
    And the "2010-01-01 7:00pm" performance should be General Admission

  Scenario: set up new showdate with reserved seating

    When I fill in the "new_showdate" fields as follows:
      | field             | value                                   |
      | show_run_dates    | date range "2010-01-01" to "2010-01-03" |
      | At                | select time "2:00 pm"                   |
      | House capacity    | 3                                       |
      | Max advance sales | 3                                       |
      | Seat map          | select "Default (4)"                    |
      | Sun               | checked                                 |
    And I press "Save & Back to List of Shows"
    Then I should see "One performance was successfully added"
    And the "2010-01-03 2:00pm" performance should use the "Default" seatmap

  @javascript
  Scenario: set up stream-anytime showdate

    When I select "Stream anytime" from "Performance type"
    And I fill in the "new_showdate" fields as follows:
      | field                  | value                            |
      | Stream available until | select time "2010-12-31 11:30pm" |
      | Max advance sales      | 50000                            |
      | Access instructions    | It's on YouTube                  |
    And I press "Save & Back to List of Shows"
    Then I should see "One performance was successfully added"
    And the "2010-12-31 11:30pm" performance should be Stream Anytime
