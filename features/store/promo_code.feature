Feature: redeem promo codes

  As a customer
  So that I can save money on tickets
  I want to redeem promo codes

Background:
  
  Given a show "The Nerd" with the following tickets available:
  | qty | type       | price  | showdate                |
  |   3 | General    | $15.00 | October 1, 2010, 7:00pm |
  |   2 | MyDiscount | $10.00 | October 1, 2010, 7:00pm |
  And the "MyDiscount" tickets for "October 1, 2010, 7:00pm" require promo code "WXYZ"
  And I am logged in as customer "Joe Tally"
  And I go to the store page
  Then the "Discount Code" field should be blank
  And I should see "General" within "#ticket-types"
  But I should not see "MyDiscount" within "#ticket-types"

Scenario: redeem promo code redirects to tickets page

  When I try to redeem the "WXYZ" discount code
  Then the "Discount Code" field should contain "WXYZ"
  And I should see "MyDiscount" within "#ticket-types"

Scenario: discount tickets disappear if promo cleared

  When I try to redeem the "WXYZ" discount code
  And I try to redeem the "" discount code
  Then I should not see "MyDiscount" within "#ticket-types"

@stubs_successful_credit_card_payment
Scenario: promo code is saved as part of voucher info

  When I try to redeem the "WXYZ" discount code
  And I select "1" from "MyDiscount - $10.00"
  And I press "Continue to Billing Info"
  And I place my order with a valid credit card
  Then customer "Joe Tally" should have the following items:
    | type    | amount | promo_code |
    | Voucher |  10.00 | WXYZ       |
