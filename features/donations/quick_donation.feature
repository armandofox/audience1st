@stubs_successful_credit_card_payment
Feature: quick donation without logging in

  As the development manager
  To make it easier for people to donate
  I want to provide a way to donate with a credit card without logging in

Scenario: donor logged in, page gets prepopulated with donor info

  Given a donation of $10 on 12/1/09 from "Tom Foolery" to the "General Fund"
  And  I am logged in as customer "Tom Foolery"
  When I go to the quick donation page

  When I fill in "Donation amount" with "15"
  And I press "Charge Donation to Credit Card"
  Then I should see "You have paid a total of $15.00 by Credit card"
  And customer "Tom Foolery" should have a donation of $15.00 to "General Fund"
  And customer "Tom Foolery" should have a donation of $10.00 to "General Fund"
  And customer "Tom Foolery" should have an order dated "12/1/2009" containing a credit_card donation of $15.00 to "General Fund"
  
Scenario: donor not logged in but has matching account

  Given a donation of $10 on 12/1/09 from "Tom Foolery" to the "General Fund"
  And   I am not logged in

  And   I go to the quick donation page
  When  I fill in the "billing_info" fields with "Tom Foolery, 123 Fake St, Oakland, CA 94601, 510-555-5555, tom@foolery.com"
  And   I fill in "Donation amount" with "20"
  And   I press "Charge Donation to Credit Card"

  Then customer "Tom Foolery" should have a donation of $20.00 to "General Fund"
  And  customer "Tom Foolery" should have a donation of $10.00 to "General Fund"
  And customer "Tom Foolery" should have an order dated "12/1/2009" containing a credit_card donation of $15.00 to "General Fund"

Scenario: donor not logged in and no previous account

  Given I am not logged in
  When I go to the quick donation page
  And I fill in the "billing_info" fields with "Joe Mallon, 123 Fake St, Oakland, CA 94611, 555-1212, joe@joescafe.com"
  And I fill in "Donation amount" with "10"
  And I press "Charge Donation to Credit Card"

  Then customer "Joe Mallon" should exist
  And customer "Joe Mallon" should have a donation of $10.00 to "General Fund"
  
