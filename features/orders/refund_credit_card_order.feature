@stubs_successful_credit_card_payment
Feature: refund an order

  As a boxoffice manager
  Because customers sometimes can't make the show and I want them to be happy
  I want to cancel and refund an order placed with a credit card

Background: customer has placed a credit card order

  Given an order for customer "Tom Foolery" paid with "credit card" containing:
  | show    | qty | type    | price | showdate             |
  | Chicago |   2 | General |  7.00 | May 15, 2010, 8:00pm |
  | Chicago |   1 | Special |  5.00 | May 15, 2010, 8:00pm |
  | Chicago |   1 | Senior  |  4.00 | May 15, 2010, 8:00pm |
  And I am logged in as boxoffice manager
  And I am on the orders page for customer "Tom Foolery"

@stubs_successful_refund
Scenario: successful refund of credit card order

  When I select all the items in that order
  And  I refund that order
  Then I should be on the order page for that order
  And  I should see "Credit card refund of $23.00 successfully processed."
  And  there should be refund items for that order with amounts: 7.00,7.00,5.00,4.00

@stubs_successful_refund
Scenario: partial refund credit card order

  When I select items 2,3 of that order
  And I refund that order
  Then I should see "Credit card refund of $12.00 successfully processed"
  And I should see "Order total: $11.00"
  And I should see /CANCELED Mary Manager.*7.00 General/
  But I should not see /CANCELED Mary Manager.*4.00 Senior/
  And there should be refund items for that order with amounts: 7.00,7.00

@stubs_successful_refund
Scenario: refund multiple items in separate transactions

  When I refund item 1 of that order
  And I refund items 3,4 of that order
  Then I should see "Order total: $7.00"
  And I should see "Credit card refund of $9.00 successfully processed"
  And there should be refund items for that order with amounts: 7.00,4.00,5.00

@stubs_failed_refund
Scenario: cannot refund credit card order

  When I refund item 1 of that order
  Then I should see "Could not process credit card refund"
  And there should be no refund items for that order
  
