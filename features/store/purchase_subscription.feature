@stubs_successful_credit_card_payment
Feature: Purchase subscription


  As a would-be patron
  So that I can become a season subscriber
  I want to buy a subscription without having an account already

Scenario: successful purchase

  Given a "Regular" subscription available to anyone for $50.00
  And I am not logged in

  When I go to the login page
  And I follow "Subscribe to Our Season"
  And I select "2" from "Regular"
  And I proceed to checkout

  Then I should be on the login page
  When I follow "Create Account"
  And I fill in the ".billing_info" fields with "Tom Foolery, 123 Fake St, Alameda, CA 94501, 510-999-9999, tomfoolery@mail.com"
  And I fill in "Password" with "wxyz"
  And I fill in "Confirm Password" with "wxyz"
  And I press "Create My Account"

  Then I should be on the checkout page for customer "Tom Foolery"
  When I place my order with a valid credit card

  Then I should see "You have paid a total of $100.00 by Credit card"
  And I should see "Back to My Tickets"
