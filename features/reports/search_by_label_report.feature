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

  When I press "Estimate number of matches"
  Then I should see "2 matches" within "#report_preview"

Scenario: display results

  When I press "Display on screen"
  Then table "#customers" should include:
    | First name | Last name |
    | Armando    | Fox       |
    | Joe        | Mallon    |
  But table "#customers" should not include:
    | First name | Last name |
    | Liz        | Moore     |
    | Dian       | Hale      |
