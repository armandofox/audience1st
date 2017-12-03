Feature: Creating group
  As an box office staff(or above level
  I want to create a group
  so that I can help my customers better

Background:
  Given I am logged in as boxoffice
  And the following Customers exist:
    | first_name | last_name | email          | street        | city | state |
    | Alex       | Fox       | afox@mail.com  | 11 Main St #1 |  SAF | CA    |
    | Armando    | Fox       | arfox@mail.com | 11 Main St    |  SAF | CA    |
    | Alice      | Fox       | BB@email.com   | 123 Fox Hill  |  SAF | CA    |
  And I search for "Fox"
  Then table "#customers" should include:
    | First name | Last name |
    | Alex       | Fox       |
    | Armando    | Fox       |
    | Alice      | Fox       |


  Scenario: Go to new group page with selecting customers
    When I select customers "Armando Fox" and "Alex For" to add to groups
    And I press "Add to group" within "#mergebar1"
    Then I should be on the add to group page

  Scenario: Creating new group with information
    When I fill in the "name field" with "Fox Family"
    And I press "Create Group" submit button
    Then I will have a group "Fox Family" with members "Armando Fox, Alex Fox"
    