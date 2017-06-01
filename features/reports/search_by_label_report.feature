@javascript
Feature: search for customers by label
 
  As the development chair
  So that I can target campaigns specifically at certain patrons who have specific roles
  I want to search for customers by label

Background:
 
  Given I am logged in as staff
  And the following customers and labels exist:
    | first_name | last_name | labels          |
    | Armando    | Fox       | Board, Musician |
    | Joe        | Mallon    | Board           |
    | Dian       | Hale      | VIP             |
    | Liz        | Moore     |                 |
  And I fill in the special report "Search customers by label" with:
    | action | field_name |
    | check  | Musician   |
    | check  | Board      |

Scenario: estimate number of matches

  When I choose "Estimate number of matches"
  And I press "Run Report"
  Then I should see an alert matching /2 matches/

Scenario: display results

  When I choose "Display list on screen"
  And I press "Run Report"
  Then table "#customers" should include:
    | First name | Last name |
    | Armando    | Fox       |
    | Joe        | Mallon    |
  But table "#customers" should not include:
    | First name | Last name |
    | Liz        | Moore     |
    | Dian       | Hale      |
