Feature: customer can specify that someone else will pickup ticket or registration
  As a boxoffice manager
  To make kids' class enrollments easier to track
  I want to let patrons specify name of person who'll pickup the order

Scenario: admin can see pickup name on door list

Scenario: customer can specify pickup name at purchase time

  Given I am logged in as customer "Tom Foolery"
  And my cart contains the following tickets:
    | qty | type    | show    | price  | showdate   |
    |   2 | General | Chicago | $10.00 | Apr 1, 8pm |
  And I am on the checkout page

