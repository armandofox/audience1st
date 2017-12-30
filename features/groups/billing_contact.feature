Feature: Billing contact  group
  As an box office staff or above level
  I want to view and edit a customer's groups in billing/contact

Background:
  Given I am logged in as boxoffice
  And the following Groups exist:
    | name            | address_line_1 | address_line_2 | city     | state | zip   | work_phone | cell_phone | group_url |
    | Fox Family | 1234 Ward St.  | Apt. A         | Berkeley | CA    | 94702 | 123456     | 654321     | url.com   |
  And the following Customers exist:
    | first_name | last_name | email          | street        | city | state |
    | Alex       | Fox       | afox@mail.com  | 11 Main St #1 |  SAF | CA    |
  And "Alex" is in the group "Fox Family"

  And I go to the edit contact info page for customer "Alex Fox"


Scenario: Links should show up
  Then I should see "Contact Info for Alex Fox"
  Then I should see "Fox Family"
  Then I should see "Manage groups"
