Feature: make a recurring donation through quick donation

Background:
  Given I am logged in as customer "Tom Foolery"
  Given admin "has" allowed recurring donations
  And I go to the quick donation page
  Then I should see "frequency"
  When I select monthly in the donation frequency radio button
  When I fill in "Donation amount" with "15"
  And I press "Charge Donation to Credit Card"

@stubs_successful_credit_card_payment
Scenario: make donation
  Then I should see "You have paid a total of $15.00 by Credit card"
  Then there should be a Recurring Donation model instance belonging to "Tom Foolery"

@stubs_failed_credit_card_payment
Scenario: attempt to make a donation but card payment fails
  Then there should not be a Recurring Donation model instance belonging to "Tom Foolery"