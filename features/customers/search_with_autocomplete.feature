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


  
Scenario:
  Given the following customers exist: Alex Fox, Armando Fox, Bob Bag
  Given customer "Dianne Feinstein" whose address street is: "123 Fox Hill Road"
  Given customer "Barbara Boxer" whose address street is: "200 Alexander Ave."
  
  When I fill "search_field" autocomplete field with "Fox"
  Then I should see autocomplete choice "Armando Fox" 
  And I should see autocomplete choice "Alex Fox"
  And I should see autocomplete choice "Dianne Feinstein(123 Fox Hill Road)"
  But I should not see autocomplete choice "Bob Bag"
  When I select autocomplete choice "Alex Fox"
  Then I should be on the home page for customer "Alex Fox"