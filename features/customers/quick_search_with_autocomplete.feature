@javascript
Feature: search with autocompletion

  As a box office worker
  So that I can help customers by phone
  I want to be able to search for a customer by various criteria

Background: I am logged in as boxoffice
  
  Given I am logged in as box office
  And the following customers exist: Frodo Baggins, Bilbo Baggins, Bob Bag

Scenario: quick search with multiple match

  When I fill autocomplete field "autocomplete" with "Bagg"
  Then I should see autocomplete choice "Bilbo Baggins" 
  But I should not see autocomplete choice "Bob Bag"
  When I select autocomplete choice "Bilbo Baggins"
  And I press "Go"
  Then I should be on the home page for customer "Bilbo Baggins"

Scenario: quick search with no matches

  When I fill autocomplete field "autocomplete" with "xyz"
  Then I should not see any autocomplete choices
