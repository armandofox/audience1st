@stubs_successful_credit_card_payment
Feature: Guest checkout

  As a box office manager
  So that I can entice people to buy tickets
  I want to enable guest checkout, so patrons just give email & billing

Background: 

  Given the boolean setting "Allow guest checkout" is "true"
  And I am not logged in  
  And my cart contains the following tickets:
    | show    | qty | type    | price | showdate             |
    | Chicago |   3 | General |  7.00 | May 15, 2010, 8:00pm |
  When I try to checkout as guest using "Joe Tally, 123 Fake St., Alameda, CA 94501, 510-999-9999, joetally@mail.com"

Scenario: successful first-time guest checkout for single-ticket purchases is followed by logout

  When I press "CONTINUE >>"
  Then I should be on the checkout page for customer "Joe Tally"
  When I place my order with a valid credit card
  Then customer "Joe Tally" should have 3 "General" tickets for "Chicago" on May 15, 2010, 8:00pm
  And customer "Joe Tally" should not be logged in
  And I should not see "Back to My Tickets"

Scenario: multiple guest checkouts to same email credit tickets to same account, even if different address/name

  When I successfully complete guest checkout
  Given my cart contains the following tickets:
    | show   | qty | type    | price | showdate             |
    | Hamlet |   1 | Special |  7.00 | May 20, 2010, 8:00pm |
  When I try to checkout as guest using "Joseph Tally, 123 Fake Street, Alameda, CA 94501, 510-888-8888, joetally@mail.com"
  And I successfully complete guest checkout
  Then customer "Joe Tally" should have 3 "General" tickets for "Chicago" on May 15, 2010, 8:00pm
  And customer "Joe Tally" should have 1 "Special" ticket for "Hamlet" on May 20, 2010, 8:00pm
  And customer "Joe Tally" should have the following attributes:
    | attribute | value             |
    | street    | 123 Fake St.      |
    | day_phone | 510-999-9999      |
    | email     | joetally@mail.com |

Scenario: no guest checkout allowed for subscription purchases or camps

  Given a "Regular" subscription available to anyone for $50.00
  When I go to the subscriptions page
  When I select "1" from "Regular"
  And I proceed to checkout
  Then I should not see "Checkout as Guest"

Scenario: if guest checkout fails because of existing account, checkout continues successfully after login

  Given customer "Joe Tally" exists with email "joetally@mail.com"
  And customer "Joe Tally" has previously logged in
  When I press "CONTINUE >>"
  Then I should see "This email address has previously been used to login with a password"
  When I login with the correct credentials for customer "Joe Tally"
  Then I should be on the checkout page for customer "Joe Tally"

Scenario: option setting can disable guest checkout
    
  Given the boolean setting "Allow guest checkout" is "false"
  And my cart contains the following tickets:
    | show      | qty | type    | price | showdate             |
    | Priscilla |   3 | General |  7.00 | May 16, 2010, 8:00pm |
  Then I should not see "Checkout as Guest"    

Scenario: no gift purchase allowed if allow_gift_tickets is true
  Given the setting "allow gift tickets" is "true"
  When I go to the store page
  Then I should not see "This order is a gift"

Scenario: no gift purchase allowed if allow_gift_tickets is false
  Given the setting "allow gift tickets" is "false"
  When I go to the store page
  Then I should not see "This order is a gift"
