Feature: Visit Store Page

  As a nonsubscriber
  I want to go to the Store page
  So that I can buy tickets for a show

  Scenario: Non-logged-in user can visit the Store page

    Given I am not logged in
    When I go to the store page
    Then I should see the "storeBannerNonSubscriber" message

  Scenario: Nonsubscriber can login and visit the Store page

    Given I am logged in as a nonsubscriber
    When I go to the store page
    Then I should see the "storeBannerNonSubscriber" message

  Scenario: Subscriber can login and visit the Store page

    Given I am logged in as a subscriber
    When I go to the store page
    Then I should see the "storeBannerSubscriber" message

