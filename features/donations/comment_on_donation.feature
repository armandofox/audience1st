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

Scenario: add comment to donation

  When I visit the donations page
  Then show me the page
  And I fill in "sponsor" as the comment on Joe Mallon's donation
