@javascript
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
      | Seat map           | select "None (general admission)"       |
      | At                 | select time "8:00pm"                    |
      
  Scenario Outline: create multiple showdates

    When I select "<dates>" as the "show_run_dates" date range
    And I check "<day1>"
    And I check "<day2>"
    And I fill in "House capacity" with "<house>"
    And I fill in "Max advance sales" with "<max>"

    And I press "Save & Back to List of Shows"
    Then I should see "<result_message>"
    And "Macbeth" should have <num> showdates

    Examples:
      | dates                        | day1 | day2 | house | max | num | result_message                                                                                                                                                                                                        |
      | "2010-05-07" to "2010-05-07" | Fri  | Fri  |    20 |  30 |   3 | No performances were added, because the Friday, May 7, 8:00 PM performance had errors: Max advance sales cannot exceed the house capacity for an in-theater performance.                                              |
      | "2010-05-07" to "2010-05-07" | Fri  | Fri  |    20 |   0 |   4 | You've added performance(s) whose max advance sales are set to zero, meaning no tickets can be purchased. If this isn't what you intended, you can click on the performance date in the Show Details view to edit it. |
      | "2010-03-10" to "2010-03-31" | Sat  | Sat  |    20 |  20 |   3 | The following performances were not created because they already exist: Saturday, Mar 13, 8:00 PM, Saturday, Mar 20, 8:00 PM, Saturday, Mar 27, 8:00 PM                                                               |
      | "2010-03-10" to "2010-03-31" | Fri  | Fri  |     0 |  20 |   3 | No performances were added, because the Friday, Mar 12, 8:00 PM performance had errors: House capacity must be greater than 0                                                                                         |
      | "2010-03-20" to "2010-04-04" | Fri  | Sat  |    20 |  20 |   6 | 3 performances were successfully added. The following performances were not created because they already exist: Saturday, Mar 20, 8:00 PM, Saturday, Mar 27, 8:00 PM                                                  |
