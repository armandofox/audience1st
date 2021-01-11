Feature: boxoffice manager can edit showdate details

  As a boxoffice manager
  So that I can control capacity and sales times
  I want to edit details for each showdate

  Background:

    Given the season start date is February 1
    And I am logged in as boxoffice manager
    And a performance of "Hamlet" on May 1, 2010, 8:00pm
    And I am on the edit showdate page for that performance

  Scenario: limit max sales

    When I fill in "Max advance sales" with "96"
    And I fill in "Description (optional)" with "Special performance"
    And I press "Save Changes"
    Then the showdate should have the following attributes:
      | attribute         | value               |
      | max_advance_sales | 96                  |
      | description       | Special performance |

  Scenario: cannot change performance date to be outside season

    When I select "February 5, 2011, 8:00pm" as the "Date and time" time
    And I press "Save Changes"
    Then I should see "Since this show belongs to the 2010 season, the performance date must be between Feb 1, 2010 and Jan 31, 2011."
    And the showdate should have the following attributes:
      | attribute | value             |
      | thedate   | 2010-05-01 8:00pm |
