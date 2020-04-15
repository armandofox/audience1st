Feature: setup multiple showdates - sad paths

  As a box office manager
  So that I can understand why some showdates didn't get created
  I want to see clear messages when not all new showdates can be added

  Background: existing showdates
    
    Given a show "Macbeth" with the following performances: Sat Mar 13 8pm, Sat Mar 20 8pm, Sat Mar 27 8pm
    And I am logged in as boxoffice manager
    And I am on the new showdate page for "Macbeth"
    And I fill in the "new_showdate" fields as follows:
      | field              | value                                   |
      | Advance sales stop | 60                                      |
      | Max advance sales  | 50                                      |
      | Seat map           | select "None (general admission)"       |
      | House capacity     | 20                                      |
      
  Scenario: no new showdates get created because they all exist

    When I fill in the "new_showdate" fields as follows:
      | field              | value                                   |
      | show_run_dates     | date range "2010-03-10" to "2010-03-31" |
      | Sat                | checked                                 |
      | At                 | select time "8:00pm"                    |
    And I press "Save & Back to List of Shows"
    Then I should see "No new performances were added."
    And I should see "The following performances were not created because they already exist: Saturday, Mar 13, 8:00 PM, Saturday, Mar 20, 8:00 PM, Saturday, Mar 27, 8:00 PM"
    And "Macbeth" should have 3 showdates
    
  Scenario: no new showdates get created because of validation errors
    
    When I fill in the "new_showdate" fields as follows:
      | field          | value                                   |
      | show_run_dates | date range "2010-03-10" to "2010-03-31" |
      | Fri            | checked                                 |
      | At             | select time "8:00pm"                    |
      | House capacity | 0                                       |
    And I press "Save & Back to List of Shows"
    Then I should see "No performances were added, because the Friday, Mar 12, 8:00 PM performance had errors: House capacity must be greater than 0"
    And "Macbeth" should have 3 showdates
    
  Scenario: some new showdates get created, others exist
    
    When I fill in the "new_showdate" fields as follows:
      | field          | value                                   |
      | show_run_dates | date range "2010-03-20" to "2010-04-04" |
      | Fri            | checked                                 |
      | Sat            | checked                                 |
      | At             | select time "8:00pm"                    |
      | House capacity | 20                                      |
    And I press "Save & Back to List of Shows"
    Then I should see "3 performances were successfully added."
    Then show me the page
    And I should see "The following performances were not created because they already exist: Saturday, Mar 20, 8:00 PM, Saturday, Mar 27, 8:00 PM"
    And "Macbeth" should have 6 showdates
