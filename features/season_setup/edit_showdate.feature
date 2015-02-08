Feature: boxoffice manager can edit showdate details

  As a boxoffice manager
  So that I can control capacity and sales times
  I want to edit details for each showdate

Background:

  Given I am logged in as boxoffice manager
  And a performance of "Hamlet" on May 1, 2011, 8:00pm
  And I am on the edit showdate page for that performance

Scenario: limit max sales

  When I fill in "Max advance sales" with "100"
  And I fill in "Description (optional)" with "Special performance"
  And I press "Save Changes"
  Then the showdate whose thedate is "2011-05-01 20:00:00" should have the following attributes:
   | max_sales   |                 100 |
   | description | Special performance |
