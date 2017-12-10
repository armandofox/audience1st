@javascript
Feature: search with autocompletion

  As a box office worker
  So that I can help customers by phone
  I want to be able to search for a customer by various criteria

Background: I am logged in as boxoffice
  
  Given I am logged in as box office
  And the following customers exist: Frodo Baggins, Bilbo Baggins, Bob Bag

Scenario: search with multiple match

  When I fill "search_field" autocomplete field with "Bagg"
  Then I should see autocomplete choice "Bilbo Baggins" 
  And I should see autocomplete choice "Frodo Baggins"
  But I should not see autocomplete choice "Bob Bag"
  When I select autocomplete choice "Bilbo Baggins"
  Then I should be on the home page for customer "Bilbo Baggins"

Scenario: search with no matches

  When I fill "search_field" autocomplete field with "xyz"
  Then I should not see any autocomplete choices

Scenario:search with other information
  Given the following Customers exist:
    | first_name | last_name | email               | street        | city | state |
    | Alex       | Fox       | afox@mail.com       | 11 Main St #1 |  SAF | CA    |
    | Armando    | Fox       | arfox@mail.com      | 11 Main St    |  SAF | CA    |
    | Bobby      | Boxer     | BB@email.com        | 123 Fox Hill  |  SAF | CA    |
    | Bob        | Bag       | BBB@email.com       | 23 Alexander  |  SAF | CA    |
    | Organ      | Milk      | dancingfox@mail.com | 100 bway      |  SAF | CA    |

  When I fill "search_field" autocomplete field with "Fox"
  Then I should see autocomplete choice "Armando Fox"
  And I should see autocomplete choice "Bobby Boxer(123 Fox Hill)"
  And I should see autocomplete choice "Organ Milk(dancingfox@mail.com)"
  But I should not see autocomplete choice "Bob Bag"

Scenario: search with no result
  When I fill "search_field" autocomplete field with "No matching result"
  Then I should see autocomplete choice "(no matches)"