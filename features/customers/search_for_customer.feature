Feature: search for customer by anything

  As a box office worker
  So that I can help customers by phone
  I want to be able to search for a customer by various criteria

Background: I am logged in as boxoffice
  
  Given I am logged in as box office
  And I am on the list of customers page

Scenario: search by last name

  When I fill in 'name' with 'Foolery'
  And I press 'Go' within '#search_on_any_field'
