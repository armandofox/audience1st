@stubs_successful_credit_card_payment
Feature: Redirecting to Personal Contact Information at Checkout

  As a customer
  So that I can checkout with the correct contact information
  I want to be redirected to the edit personal contact page

Background: 
  Given I am logged in as customer "Tom Foolery" with no address

Scenario: Redirect to personal information page when checkout without necessary info
  Given my cart contains the following tickets: 
  	| show  | showdate                | type | price | qty |
  	| Shrek | October 1, 2010, 7:00pm | reg  | 10.00 | 1   |
  Then I should be on the checkout page
  When I fill in a valid credit card for "Tom Foolery"
  And I press "Charge Credit Card"
  Then I should be on the edit contact info page
  And I should see "Purchaser information is incomplete"
  And I fill in the following:
    | Street | 123 Fake Street |
    | City   | Berkeley        |
    | State  | CA              |
    | Zip    | 93123           |
  And I press "Save Changes"
  Then I should be on the checkout page
