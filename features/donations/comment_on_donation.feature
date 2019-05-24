@javascript
Feature: add or edit comment on donation

  As a development manager
  So that I can keep notes about specific donations
  I want to add comments on donations after they are made

Background:

  Given I am logged in as staff
  And the following donations:
    | donor       | amount  | fund              |       date | comment   |
    | Tom Foolery | $100.00 | 0000 General Fund | 2012-01-03 | anonymous |
    | Joe Mallon  | $500.00 | 9998 History Fund | 2012-01-04 |           |
  And I visit the donations page
  
Scenario: add comment to donation

  When I fill in "sponsor" as the comment on Joe Mallon's donation
  And I press "✔" within "#donation_row_2"
  Then customer "Joe Mallon" should have a donation of $500.00 to "History Fund" with comment "sponsor"
  And customer "Tom Foolery" should have a donation of $100.00 to "General Fund" with comment "anonymous"

Scenario: edit existing comment

  When I fill in "VIP" as the comment on Tom Foolery's donation
  And I press "✔" within "#donation_row_1"
  Then customer "Tom Foolery" should have a donation of $100.00 to "General Fund" with comment "anonymous"

Scenario: remove comment from donation  

  When I fill in "" as the comment on Tom Foolery's donation
  And I press "✔" within "#donation_row_1"
  Then customer "Tom Foolery" should have a donation of $100.00 to "General Fund" with comment ""
