Feature: Visit Store Page

  So that I can buy tickets for a show
  As a patron
  I want to go to the Store page

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
    Then I should see the NonSubscriber message
