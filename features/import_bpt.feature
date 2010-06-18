Feature: import Brown Paper Tickets will-call lists

  As a box office manager
  So that I can have historical patron attendance data
  I want to import a will-call list from Brown Paper Tickets

Background:
  Given I am logged in as boxoffice manager
  And I follow "Box Office"
  Then I should see "Import Will-Call List"
  When I follow "Import Will-Call List"
  Then I should see "Brown Paper Tickets" within "select[name=vendor]"

