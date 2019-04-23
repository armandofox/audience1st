Feature: self-service comps

  As a boxoffice manager
  So that I can paper the house
  I want customers to be able to self-purchase comps with a promo code

Background: show with self-service comps available

  Given the boolean setting "Allow guest checkout" is "true"
  And I am not logged in
  And 2 "PromoComp" comps are available for "Hamlet" on "Oct 1, 2010, 8pm" with promo code "YORICK"
  And 2 General vouchers costing $10 are available for that performance 
  Then I should not see "PromoComp - $0.00"
  When I try to redeem the "YORICK" discount code
  
Scenario: successfully purchase comps as guest

  When I select "2" from "PromoComp - $0.00"
  When I proceed to checkout
  And I try to checkout as guest using "Joe Tally, 123 Fake St., Alameda, CA 94501, 510-999-9999, joetally@mail.com"
  And I press "CONTINUE >>"
  Then the cart should contain 2 "PromoComp" tickets for "Oct 1, 2010, 8pm"
  When I press "Complete Comp Order"
  Then customer "Joe Tally" should have 2 "PromoComp" tickets for "Hamlet" on Oct 1, 2010, 8pm

@stubs_successful_credit_card_payment
Scenario: purchase both comps and regular tickets
  
  When I select "2" from "PromoComp - $0.00"
  When I select "1" from "General - $10.00"
  And I proceed to checkout
  And I try to checkout as guest using "Joe Tally, 123 Fake St., Alameda, CA 94501, 510-999-9999, joetally@mail.com"
  And I successfully complete guest checkout
  Then I should see "You have paid a total of $10.00 by Credit card"
  Then customer "Joe Tally" should have 2 "PromoComp" tickets for "Hamlet" on Oct 1, 2010, 8pm
  And customer "Joe Tally" should have 1 "General" ticket for "Hamlet" on Oct 1, 2010, 8pm
