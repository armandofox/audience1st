Feature: Deleting Customer from group
  As an box office staff(or above level
  I want to delete a customer from a group
  so that I can undo a mistake
Background:
  Given I am logged in as boxoffice
  And the following Customers exist:
    | first_name | last_name | email          | street        | city | state |
    | Alex       | Fox       | afox@mail.com  | 11 Main St #1 |  SAF | CA    |
    | Armando    | Fox       | arfox@mail.com | 11 Main St    |  SAF | CA    |
  Given the following Groups exist:
    | name            | address_line_1 | address_line_2 | city     | state | zip   | work_phone | cell_phone | group_url |
    | Fox Family | 1234 Ward St.  | Apt. A         | Berkeley | CA    | 94702 | 123456     | 654321     | url.com   |
  And "Alex" is in the group "Fox Family"
  And "Armando" is in the group "Fox Family"
  And I enter the groups page for "Fox Family"
  Scenario: deleting from group with no customers selected should fail
    And I press "Delete from Group"
    Then I should see "Editing Fox Family"
    Then I should see "No Customers Selected"



  Scenario: deleting customer from group should successfully delete customer without removing from database
    Then I should see "Alex"
    Then I should see "Armando"
    And I should see "Fox Family"
    And I select the following customers: "Alex Fox"
    And I press "Delete from Group"
    Then I should see "Fox Family"
    Then I should see "Armando"
    Then I should not see "Alex"
    And the customer "Alex" should be in the database
