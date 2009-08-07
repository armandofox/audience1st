Feature: Nonsubscriber Browse Showdates

  So that I can buy tickets for a show
  As a nonsubscriber
  I want to see upcoming show dates

  Scenario: Select show with available showdates

    Given I visit the Store page
    When I select a show with available showdates
    Then I should see available showdates for that show

  Scenario: Select unavailable showdate

    Given a show
    When I select an upcoming showdate with 0 regular tickets available
    Then I should see "No tickets on sale for this performance"

  Scenario: Select regular tickets for showdate with only one ticket type available

    Given a show
    When I select an upcoming showdate with 3 regular tickets available
    Then I should see a menu allowing me to select 1 to 3 tickets

  Scenario: Select regular tickets for showdate with 3 ticket types available

    Given a show
    When I select an upcoming showdate with 2 regular tickets available
    Then I should see 3 menus each allowing me to select 0 to 2 tickets

  Scenario:

