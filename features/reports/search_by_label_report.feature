@wip @javascript
Feature: search for customers by label
 
  As the development chair
  So that I can target campaigns specifically at certain patrons who have specific roles
  I want to search for customers by label

Background:
 
  Given I am logged in as staff
  And the following customers and labels exist:
    | first   | last   | labels          |
    | Armando | Fox    | Board, Musician |
    | Joe     | Mallon | Board           |
    | Dian    | Hale   | VIP             |
    | Liz     | Moore  |                 |
  And I run the special report "Search customers by label" with:
    | action | field_name | value |
    | select | labels     | Board |

