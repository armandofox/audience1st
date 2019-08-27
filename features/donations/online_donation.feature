Feature: dedicated landing page for online donations

  As a patron
  So that I can support the theater's various missions
  I want to easily make online donations and know what fund they're supporting

Background:

  Given the following account codes exist:
  | name             | code | description                                                     | donation_prompt          |
  | History Fund     | 7575 | The History Fund supports exhibits about the theater's history. |                          |
  | Show Sponsorship | 8080 | Sponsorship of Altarena productions                             | Name of show to sponsor: |
  And I am logged in as customer "Tom Foolery"

Scenario: landing on donation page with valid account code
  When I visit the donation landing page coded for fund 7575
  Then I should see "Donation to History Fund"
  And I should see "exhibits about the theater's history"
  When I fill in "donation" with "65"
  And I press "submit"
  Then I should be on the Checkout page
  And I should see "Donation to History Fund"
  And I should see "$65.00"

Scenario: not filling in a donation amount should return you to donation page
  When I visit the donation landing page coded for fund 7575
  And  I press "submit"
  Then I should see "Donation to History Fund"

Scenario: landing on donation page with invalid account code
  When I visit the donation landing page coded for a nonexistent fund
  Then I should see "Donation to General Fund"

Scenario: change donation prompt
  When I login as boxoffice manager
  And I change the "Donation prompt" for account code 7575 to "Donate to support our history"
  And I visit the donation landing page coded for fund 7575
  Then I should see "Donate to support our history"

@stubs_successful_credit_card_payment
Scenario: contents of donation prompt field are recorded as donation comment
  When I visit the donation landing page coded for fund 8080
  Then I should see "Donation to Show Sponsorship"
  When I fill in "Name of show to sponsor:" with "Guys and Dolls"
  And I fill in "donation" with "999"
  And I press "submit"
  Then I should be on the Checkout page
  And I should see "Donation to Show Sponsorship Guys and Dolls"
  When I place my order with a valid credit card
  Then customer "Tom Foolery" should have a donation of $999 to "Show Sponsorship" with comment "Guys and Dolls"
