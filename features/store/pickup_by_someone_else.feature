Feature: customer can specify that someone else will pickup ticket or registration
  As a boxoffice manager
  To make kids' class enrollments easier to track
  I want to let patrons specify name of person who'll pickup the order

Background: customer is logged in
  Given I am logged in as customer "Tom Foolery"
  And today is April 1, 2013

Scenario: admin can see pickup name on door list

Scenario: customer can specify pickup name at purchase time

  And my cart contains the following tickets:
    | qty | type    | show    | price  | showdate   |
    |   2 | General | Chicago | 10.00  | Apr 2, 2013, 8pm  |
  And I am on the checkout page
  Then I should see "If someone other than the purchaser will be attending this event"
  When I fill in "pickup" with "Jason Gray"
  And I pay with a valid credit card

Scenario: customer cannot specify alternate person for donation-only order
  
  Given I am logged in as customer "Tom Foolery"
  And I visit the donation landing page coded for fund 7575
  And I fill in "donation" with "50"
  And I press "submit"
  Then I should be on the Checkout page
  And I should not see "If someone other than the purchaser will be attending this event"
