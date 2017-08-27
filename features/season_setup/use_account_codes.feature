Feature: use account codes

  As the bookkeeper
  So that I can simplify reconciliation
  I want to setup and edit account codes for financial reporting categories

Background:

  Given I am logged in as administrator
  And I am on the account codes page

Scenario: create new account code

  When I follow "Add New Account Code"
  Then I should be on the new account code page
  When I fill in "Name" with "Single Ticket"
  And I fill in "Code" with "2222"
  And I press "Create"
  Then I should be on the account codes page
  And I should see "Single Ticket" within "table"
  And I should see "2222" within "table"

