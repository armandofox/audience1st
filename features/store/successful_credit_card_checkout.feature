@stubs_successful_credit_card_payment
Feature: Successful checkout with credit card

  As a patron
  So that I can purchase my tickets 
  I want to checkout with a credit card

  Background:
    Given I am logged in as customer "Tom Foolery"

  Scenario: successful credit card payment without donation

    Given my cart contains the following tickets:
      | show    | qty | type    | price | showdate             |
      | Chicago |   3 | General |  7.00 | May 15, 2010, 8:00pm |
    Then I should be on the checkout page
    And the billing customer should be "Tom Foolery"
    When I place my order with a valid credit card
    Then I should be on the order confirmation page for customer "Tom Foolery"
    And I should see "You have paid a total of $21.00 by Credit card"
    And customer "Tom Foolery" should have 3 "General" tickets for "Chicago" on May 15, 2010, 8:00pm

  Scenario: successful gift order without donation

    Given my gift order contains the following tickets:
      | show    | qty | type    | price | showdate             |
      | Chicago |   2 | General |  7.00 | May 15, 2010, 8:00pm |
    Then I should be on the shipping info page for customer "Tom Foolery"
    When I fill in the ".billing_info" fields with "Al Smith, 123 Fake St., Alameda, CA 94501, 510-999-9999, alsmith@mail.com"
    And I proceed to checkout
    Then I should be on the checkout page
    And the gift recipient customer should be "Al Smith"
    And the billing customer should be "Tom Foolery"
    When  I place my order with a valid credit card
    Then I should be on the order confirmation page for customer "Tom Foolery"
    And customer "Tom Foolery" should have 0 "General" tickets for "Chicago" on May 15, 2010, 8:00pm
    And customer "Al Smith" should have 2 "General" tickets for "Chicago" on May 15, 2010, 8:00pm

  Scenario: successful subscription purchase

    Given a "Super Sub" subscription available to anyone for $60.00
    And the "Super Sub" subscription includes the following vouchers:
    | name      | quantity |
    | Hamlet    |        2 |
    | King Lear |        1 |
    And my cart contains 3 "Super Sub" subscriptions
    When I place my order with a valid credit card
    Then I should be on the order confirmation page
    And I should see "You have paid a total of $180.00 by Credit card"
    And customer "Tom Foolery" should have the following vouchers:
    | vouchertype            | quantity |
    | Super Sub              |        3 |
    | Hamlet (subscriber)    |        6 |
    | King Lear (subscriber) |        3 |

  Scenario: successful purchase even if customer doesn't have address info

    Given customer "Tom Foolery" has no contact info
    And my cart contains the following tickets:
      | show    | qty | type    | price | showdate             |
      | Chicago |   3 | General |  7.00 | May 15, 2010, 8:00pm |
    When I press "Charge Credit Card"
    Then I should see "Street can't be blank"
    When I fill in the address as "123 Fake St, Oakland, CA 94611"
    And I press "Charge Credit Card"
    Then I should be on the order confirmation page for customer "Tom Foolery"
    And I should see "You have paid a total of $21.00 by Credit card"
    And customer "Tom Foolery" should have 3 "General" tickets for "Chicago" on May 15, 2010, 8:00pm
    And customer "Tom Foolery" should have the following attributes:
      | attribute | value       |
      | street    | 123 Fake St |
      | city      | Oakland     |
      | state     | CA          |
      | zip       | 94611       |
