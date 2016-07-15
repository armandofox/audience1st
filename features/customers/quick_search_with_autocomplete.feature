@javascript
Feature: search with autocompletion

  As a box office worker
  So that I can help customers by phone
  I want to be able to search for a customer by various criteria

Background: I am logged in as boxoffice
  
  Given I am logged in as box office
  And the following customers exist: Frodo Baggins, Bilbo Baggins, Bob Bag

Scenario: quick search with no match

  When I fill autocomplete field "autocomplete" with "fro"
  Then I should see autocomplete choice "Frodo Baggins" 
  When I select autocomplete choice "Frodo Baggins"
  And I press "Go"

