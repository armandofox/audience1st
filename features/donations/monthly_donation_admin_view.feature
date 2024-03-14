@javascript
Feature: allow recurring donations
    As an admin
    So that customers can setup recurring donations
    I want to allow recurring donations

Background:
    Given I am logged in as administrator
    And I visit the admin:settings page

Scenario: Allow Monthly Recurring Donations
    When I set allow recurring donations to "Yes"
    Then the radio button to select the default donation type should be "visible"
    Then the radio button to select the default donation type should be set to "one"
    And I press "Update Settings"
    Then I should see "Update successful"

Scenario: Disallow Monthly Recurring Donations
    When I visit the admin:settings page
    And I set allow recurring donations to "No"
    Then the radio button to select the default donation type should be "hidden"
    And I press "Update Settings"
    Then I should see "Update successful"