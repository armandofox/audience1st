Feature: admin can create customer

  As an admin
  So that I can track customers better
  I want to create a new customer record

Background:

  Given I am logged in as boxoffice

Scenario: admin can create customer by name only

  When I visit the add customer page for staff
  And I fill in the following:
  | First name | Bob    |
  | Last name  | Barker |
  And I press "Create"
  Then customer "Bob Barker" should exist
  And I should be on the home page for customer "Bob Barker"


