Feature: record donation

  As the development manager
  So that I can track donations and properly date them
  I want to record donations and be able to set date and comments

Background:

  Given I am logged in as boxoffice manager
  And I am on the home page for customer "Tom Foolery"
  And I follow "New Donation..."

Scenario: record valid check donation

  When I record a check donation of $55.55 to "General Fund" on Jan 1, 2009 with comment "Check #2222"
  And I press "Record"
  Then customer "Tom Foolery" should have an order dated "Jan 1, 2009" containing a check donation of $55.55 to "General Fund"

@stubs_failed_credit_card_payment
Scenario: attempt donation with invalid credit card

  When I fill in "Amount" with "30.00"
  And I choose "Credit Card"
  And I fill in the "Credit Card Information" fields as follows:
  | field    |            value |
  | Number   | 4000000000000002 |
  | CVV code |              111 |
  And I press "Charge Credit Card"
  Then I should be on the record donation page for customer "Tom Foolery"
  Then I should see "Forced failure in test mode"
  When I go to the donations page
  Then I should see "0 transactions, $0.00"
