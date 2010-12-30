Feature: Visit Store Page

  As a nonsubscriber
  I want to go to the Store page
  So that I can buy tickets for a show

  Scenario: Non-logged-in user adds tickets to cart

    Given a show "Chicago" with "General" tickets for $17.00 on "April 15, 2010"
    And I am not logged in
    And today is April 1, 2010

    When I go to the store page
    Then I should see /Chicago/ within "select[name=show]"
    And I should see /Apr 15/ within "select[name=showdate]"


