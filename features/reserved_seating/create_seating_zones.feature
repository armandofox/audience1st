Feature: create, edit, delete seating zones

  As a box office manager
  So that I can manage different seat maps and seating zones
  I want to create, edit, and delete seating zones for seatmaps

  Background: logged in as boxoffice manager

    Given I am logged in as boxoffice manager
    And I am on the seating zones page

  Scenario: create valid seating zone

    When I fill in the following within "tr[@id='new-seating-zone']":
    | seating_zone_display_order | 10      |
    | seating_zone_name          | Premium |
    | seating_zone_short_name    | pr      |
    And I press "Create"
    Then I should see "Seating zone 'pr' (Premium) created successfully."
    And seating zone "Premium (pr)" with display order 10 should exist

  Scenario: invalid parameters, since seating zone 'res' already exists in test mode

    When I fill in the following within "tr[@id='new-seating-zone']":
    | seating_zone_display_order | 10      |
    | seating_zone_name          | Regular |
    | seating_zone_short_name    | res     |
    And I press "Create"
    Then I should see "Short name has already been taken"

  Scenario: delete seating zone that's not used by any seatmap

