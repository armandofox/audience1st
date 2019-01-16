@javascript
Feature: search with autocompletion

  As a box office worker
  So that I can help customers by phone
  I want to be able to search for a customer by various criteria

Background: I am logged in as boxoffice
  
  Given I am logged in as box office

Scenario: search with multiple match

  Given the following customers exist: Frodo Baggins, Bilbo Baggins, Bob Bag
  When I search for customers matching "Bagg"
  Then the search results dropdown should include: Bilbo Baggins, Frodo Baggins
  But the search results dropdown should not include: Bob Bag
  When I select autocomplete choice "Bilbo Baggins"
  Then I should be on the home page for customer "Bilbo Baggins"

Scenario:search with other information

  Given the following customers exist:
    | first_name | last_name | email               | street        | city | state |
    | Alex       | Fox       | afox@mail.com       | 11 Main St #1 |  SAF | CA    |
    | Armando    | Fox       | arfox@mail.com      | 11 Main St    |  SAF | CA    |
    | Bobby      | Boxer     | BB@email.com        | 123 Fox Hill  |  SAF | CA    |
    | Bob        | Bag       | BBB@email.com       | 23 Alexander  |  SAF | CA    |
    | Organ      | Milk      | dancingfox@mail.com | 100 bway      |  SAF | CA    |

  When I search for customers matching "FOX"
  Then the search results dropdown should include: Armando Fox, Bobby Boxer (123 Fox Hill), Organ Milk (dancingfox@mail.com)
  But the search results dropdown should not include: Bob Bag
  When I select autocomplete choice "Bobby Boxer (123 Fox Hill)"
  Then I should be on the home page for customer "Bobby Boxer"

Scenario: search with no result
  When I search for customers matching "No matching result"
  Then the search results dropdown should include: (no matches)

Scenario: list all in autocomplete
  Given the following customers exist: Armando Fox, Foxy Armando
  When I search for customers matching "Fox"
  And I select autocomplete choice to show all matches
  Then I should be on the list of customers page

Scenario: duplicates are not listed in dropdown
  Given customer "Armando Fox" exists with email "fox@gmail.com"
  When I search for customers matching "fox"
  Then the search results dropdown should include: Armando Fox
  But  the search results dropdown should not include: Armando Fox (fox@gmail.com)
