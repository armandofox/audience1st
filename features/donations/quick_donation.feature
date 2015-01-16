Feature: quick donation without logging in

  As the development manager
  To make it easier for people to donate
  I want to provide a way to donate with a credit card without logging in

Scenario: donor logged in, page gets prepopulated with donor info

@stubs_successful_credit_card_payment
Scenario: donor not logged in but has matching account

  Given I am logged in as customer "Tom Foolery"
  When I go to the quick donation page
  Then the billing customer should be "Tom Foolery"

  When I fill in "Donation amount" with "15"
  And I press "Charge Donation to Credit Card"
  Then I should see "You have paid a total of $15.00 by Credit card"
  Then debugger
  And customer "Tom Foolery" should have a donation of $15.00 to "General Fund"
  

Scenario: donor not logged in and no previous account

  Given I am not logged in
  When I go to the quick donation page
  And I fill in the "billing_info" fields with "Joe Mallon, 123 Fake St, Oakland, CA 94611, 555-1212, joe@joescafe.com"
  
