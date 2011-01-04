Feature: import Brown Paper Tickets will-call lists

  As a box office manager
  So that I can have historical patron attendance data
  I want to import a will-call list from Brown Paper Tickets

Background:
  Given I am logged in as boxoffice manager
  And I am on the Admin:Import page
  When I follow "Import"
  Then I should see "What do you want to import?"
  And I should see "Brown Paper Tickets sales for 1 production" within "select[name=vendor]"

