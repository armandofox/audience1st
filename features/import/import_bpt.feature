@wip
Feature: import Brown Paper Tickets will-call lists

  As a box office manager
  So that I can have historical patron attendance data
  I want to import a will-call list from Brown Paper Tickets

Background:

  Given I am logged in as boxoffice manager

Scenario: try to import when no show

  Given there are no shows set up
  When I go to the Admin:Import page
  Then I should see "You have not set up any shows"
  And I should not see "For will-call lists: which show is this for?"

Scenario: import BPT sales for run of an existing show

  Given there is a show named "Chicago"
  When I go to the Admin:Import page
  Then I should see "What do you want to import?"
  And I should see "Brown Paper Tickets sales for 1 production" within "select#import_type"

