Feature: dedicated landing page for online donations

  As a patron
  So that I can support the theater's various missions
  I want to easily make online donations and know what fund they're supporting

Background:

  Given the following account codes exist:
  | name         | code | description                                                     |
  | History Fund | 7575 | The History Fund supports exhibits about the theater's history. |
  | Default Fund | 4040 |                                                                 |
  And I am logged in as customer "Tom Foolery"

Scenario: landing on donation page with valid account code
  When I visit the donation landing page coded for fund 7575
  Then I should see "Donation to History Fund"
  And I should see "exhibits about the theater's history"
  When I fill in "donation" with "65"
  And I press "submit"
  Then I should be on the Checkout page
  Then show me the page
  And I should see "Donation to History Fund"
  And I should see "$65.00"

Scenario: not filling in a donation amount should return you to donation page
  When I visit the donation landing page coded for fund 7575
  When I press "submit"
  Then I should be on the donation landing page coded for fund 7575

Scenario: landing on donation page with invalid account code
  When I visit the donation landing page coded for fund 1234
  Then I should see "Donation to General Fund"
