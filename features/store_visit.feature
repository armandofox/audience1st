Feature: Visit Store Page

  As a nonsubscriber
  I want to go to the Store page
  So that I can buy tickets for a show

  Scenario: Starting from scratch

    Given I am not logged in
    When I visit the store page
    Then I should see the NonSubscriber message

  Scenario: Nonsubscriber logs in

    Given I am logged in as a nonsubscriber
    When I visit the store page
    Then I should see the NonSubscriber message

  Scenario: Subscriber logs in

    Given I am logged in as a subscriber
    When I visit the store page
    Then I should see the Subscriber message
