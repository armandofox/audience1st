@stubs_successful_credit_card_payment
Feature: quick donation without logging in

  As the development manager
  To make it easier for people to donate
  I want to provide a way to donate with a credit card without logging in

Scenario: donor logged in, page gets prepopulated with donor info

  Given a donation of $10 on 2009-12-01 from "Tom Foolery" to the "General Fund"
  And  I am logged in as customer "Tom Foolery"
  When I go to the quick donation page

  When I fill in "Donation amount" with "15"
  And I press "Charge Donation to Credit Card"
  Then I should see "You have paid a total of $15.00 by Credit card"
  And customer "Tom Foolery" should have a donation of $15.00 to "General Fund"
  And customer "Tom Foolery" should have a donation of $10.00 to "General Fund"
  And customer "Tom Foolery" should have an order dated "2009-12-01" containing a check donation of $10.00 to "General Fund"
  
Scenario: donor not logged in but has matching account

  Given customer "Tom Foolery" exists with email "fool@gmail.com"
  And customer "Tom Foolery" has no contact info

  And   I am not logged in

  And   I go to the quick donation page
  When  I fill in the ".billing_info" fields with "Tom Foolery, 123 Fake St, Oakland, CA 94601, 510-555-5555, fool@gmail.com"
  And   I fill in "Donation amount" with "20"
  And   I press "Charge Donation to Credit Card"

  Then I should see "Donation to General Fund $20.00"
  And customer "Tom Foolery" should have a donation of $20.00 to "General Fund"
  And  customer "Tom Foolery" should have a donation of $10.00 to "General Fund"
  And customer "Tom Foolery" should have an order dated "2010-01-01" containing a credit_card donation of $20.00 to "General Fund"
  And I should not see "Back to My Tickets"
  And customer "Tom Foolery" should not be logged in

Scenario: donor not logged in and no previous account

  Given I am not logged in
  When I go to the quick donation page
  And I fill in the ".billing_info" fields with "Joe Mallon, 123 Fake St, Oakland, CA 94611, 555-1212, joe@joescafe.com"
  And I fill in "Donation amount" with "10"
  And I press "Charge Donation to Credit Card"
  Then I should see "Thank You for Your Purchase!"
  And customer "Joe Mallon" should exist
  And customer "Joe Mallon" should have a donation of $10.00 to "General Fund"
  And I should not see "Back to My Tickets"
  And customer "Joe Mallon" should not be logged in
  
Scenario: admin logged in, records donation on behalf of patron

  Given I am logged in as boxoffice manager
  When I switch to customer "Joe Mallon"
  And I follow "Donate"
  And I fill in "Donation amount" with "9"
  And I press "Charge Donation to Credit Card"
  Then I should see "Thank You for Your Purchase!"
  And customer "Joe Mallon" should have a donation of $9.00 to "General Fund"
  
