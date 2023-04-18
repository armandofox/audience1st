@javascript
Feature: designate house seats when adding performances

  As a boxoffice manager
  So that I can set aside premium seats for VIPs
  I want to designate house seats when I add performances to a show

  Background: 

    Given I am logged in as box office manager
    And the seatmap "Default" exists
    And there is a show named "Hamlet"
    And I am on the new showdate page for "Hamlet"

  Scenario: add house seats for reserved seating performance

    When I select "Default (4)" from "Seat map"
    And I choose seats "Reserved-B1,Reserved-B2"
    And I fill in the "new_showdate" fields as follows:
      | field             | value                                   |
      | Thu               | checked                                 |
      | Fri               | checked                                 |
      | Sun               | checked                                 |
      | At                | select time "7:00pm"                    |
      | Max advance sales | 4                                       |
    And I press "Save & Back to List of Shows"
    Then I should see "One performance was successfully added"
    And the "Jan 1, 2010, 7pm" performance should have house seats "B1,B2"
    When I visit the edit showdate page for Jan 1, 2010, 7pm
    Then the "House seats" field should contain "B1,B2"
