Feature: Add customers to existing groups
  As an box office staff(or above level
  I want to add customers to existing groups
  so that I can help my customers better

Background:
  Given I am logged in as boxoffice
  Given the following Customers exist:
    | first_name | last_name | email          | created_by_admin | street        | password | password_confirmation | city | state |   zip | last_login | updated_at |
    | MaryJane   | Weigandt  | mjw@mail.com   | true             | 11 Main St    |          |                       | Oak  | CA    | 99994 | 2011-01-03 | 2011-01-01 |
    | Janey      | Weigandt  | janey@mail.com | false            | 11 Main St #1 | blurgle  | blurgle               | Oak  | CA    | 99949 | 2010-01-01 | 2010-01-01 |

  Given the following Groups exist:
    | name            | address_line_1 | address_line_2 | city     | state | zip   | work_phone | cell_phone | group_url |
    | Weigandt Family | 1234 Ward St.  | Apt. A         | Berkeley | CA    | 94702 | 123456     | 654321     | url.com   |
    | Happy Comp.     | 4321 Ward St.  | Floor 4        | Berkeley | CA    | 94702 | 123456     | 654321     | cap.com   |


  And I select customers "MaryJane Weigandt" to add to groups
  And I press "Manage groups" within "#mergebar1"
  Then I should be on the add to group page
  Then I should see "MaryJane Weigandt"

  Scenario: Add to a single existing group
    And I select groups "Weigandt Family"
    And I press the button "Update Groups"
    Then I will have a group "Weigandt Family" with members "MaryJane Weigandt"

  Scenario: Add to multiple existing groups
    And I select groups "Weigandt Family, Happy Comp."
    And I press the button "Update Groups"
    Then I will have a group "Weigandt Family" with members "MaryJane Weigandt"
    And I will have a group "Happy Comp." with members "MaryJane Weigandt"
