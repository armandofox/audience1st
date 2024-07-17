@stubs_successful_credit_card_payment
Feature: quick donation without logging in

  As the development manager
  To make it easier for people to donate
  I want to provide a way to donate with a credit card without logging in

Background:
  Given the following account codes exist:
  | name             | code | description                                                     | donation_prompt          |
  | Soda Fund        | 0504 | The Soda Funds aims to put a Soda Fountain in Soda Hall         |                          |

Scenario: donor logged in, page gets prepopulated with donor info

  Given a donation of $10 on 2009-12-01 from "Tom Foolery" to the "General Fund"
  And  I am logged in as customer "Tom Foolery"
  When I go to the quick donation page

  When I fill in "Donation amount" with "15"
  And I press "Charge Donation to Credit Card"
  Then I should see "You have paid a total of $15.00 by Credit card"
  And an email should be sent to customer "Tom Foolery" containing "A1 Staging Theater thanks you for your donation!"
  And an email should be sent to customer "Tom Foolery" containing "15.00  Donation to General Fund"
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
  And customer "Tom Foolery" should have a donation of $10.00 to "General Fund"
  And an email should be sent to customer "Tom Foolery" containing "$ 20.00  Donation to General Fund"
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
  And an email should be sent to customer "Joe Mallon" containing "$ 10.00  Donation to General Fund"
  And I should not see "Back to My Tickets"
  And customer "Joe Mallon" should not be logged in
  
Scenario: donor not logged in and provides valid address but no email

  Given I am not logged in
  When I go to the quick donation page
  And I fill in the ".billing_info" fields with "Joe Mallon, 123 Fake St, Oakland, CA 94611, 555-1212, "
  And I fill in "Donation amount" with "10"
  And I press "Charge Donation to Credit Card"
  Then I should see "Thank You for Your Purchase"
  And customer "Joe Mallon" should exist with email ""
  
Scenario: donor has account, is not logged in, and provides different billing address than account

  Given I am not logged in
  And customer "Joe Mallon" exists with email "joe@joescafe.com"
  When I go to the quick donation page
  And I fill in the ".billing_info" fields with "Joe Mallon, 99999 New Address, Oakland, CA 94611, 555-1212, joe@joescafe.com"
  And I fill in "Donation amount" with "10"
  And I press "Charge Donation to Credit Card"
  Then I should see "Thank You for Your Purchase"
  And an email should be sent to customer "Joe Mallon" containing "$ 10.00  Donation to General Fund"
  And customer "Joe Mallon" should have the following attributes:
    | attribute | value             |
    | street    | 99999 New Address |
    | city      | Oakland           |
    | state     | CA                |
    | zip       | 94611             |

Scenario: admin logged in, records donation on behalf of patron

  Given I am logged in as boxoffice manager
  When I switch to customer "Joe Mallon"
  And I follow "Donate"
  And I fill in "Donation amount" with "9"
  And I press "Charge Donation to Credit Card"
  Then I should see "Thank You for Your Purchase!"
  And customer "Joe Mallon" should have a donation of $9.00 to "General Fund"
  And an email should be sent to customer "Joe Mallon" containing "$  9.00  Donation to General Fund"

Scenario: landing on quick donation page with valid account code
  Given I am logged in as customer "Tom Foolery"
  When I visit the quick donation landing page for account code 0504
  Then I should not see "Donate to"
  And I should see "Soda Fund"
  And I should see "The Soda Funds aims to put a Soda Fountain in Soda Hall Address"

Scenario: landing on quick donation page with invalid account code
  Given I am logged in as customer "Tom Foolery"
  When I visit the quick donation landing page for account code 0505
  Then I should see "Invalid Fund ID"

Scenario: landing on quick donation page with no account code
  Given I am logged in as customer "Tom Foolery"
  When I go to the quick donation page
  Then I should not see "Donate to"
  And I should see "General Fund"
  And I should see "General Fund Address"
  
Scenario: landing on quick donation page with valid account code and making quick donation
  Given I am logged in as customer "Tom Foolery"
  When I go to the quick donation page
  And I fill in "Donation amount" with "15"
  And I press "Charge Donation to Credit Card"
  Then I should see "You have paid a total of $15.00 by Credit card"
  And customer "Tom Foolery" should have a donation of $15.00 to "Soda Fund"
  

Scenario: customer not logged in, logs in for a quicker checkout

  Given customer "Tom Foolery" has email "tom@foolery.com" and password "pass"
  And I am not logged in
  When I go to the quick donation page
  And I fill in "email" with "tom@foolery.com"
  And I fill in "password" with "pass"
  And I press "Login"
  When I fill in "Donation amount" with "15"
  And I press "Charge Donation to Credit Card"
  Then I should see "You have paid a total of $15.00 by Credit card"
  And customer "Tom Foolery" should have a donation of $15.00 to "General Fund"
  