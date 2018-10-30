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
  And I am not logged in
  And I go to the store page
  Then the "Discount Code" field should be blank
  And I should see "General" within "#voucher_menus"
  But I should not see "MyDiscount" within "#voucher_menus"

Scenario: redeem promo code redirects to tickets page

  When I try to redeem the "WXYZ" discount code
  Then the "Discount Code" field should contain "WXYZ"
  And I should see "MyDiscount" within "#voucher_menus"

Scenario: discount tickets disappear if promo cleared

  When I try to redeem the "WXYZ" discount code
  And I try to redeem the "" discount code
  Then I should not see "MyDiscount" within "#voucher_menus"
