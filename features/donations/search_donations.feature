5oFeature: search donations

  As a development manager
  So that I can find our best donors to help grow the theater
  I want to search our donation history

Background:

  Given I am logged in as staff
  And the following donations:
   | donor         | amount  | fund              | date     |
   | Tom Foolery   | $100.00 | 9999 General Fund | 1/3/2012 |
   | Joe Mallon    | $500.00 | 9998 History Fund | 1/4/2012 |
   | Armando Fox   | $600.00 | 9999 General Fund | 3/5/2012 |
   | Diana Moore   | $900.00 | 9998 History Fund | 7/1/2012 |
   | Patrick Tracy | $800.00 | 9997 Misc Fund    | 8/1/2012 |

Scenario: filter donations by fund
  
  When I visit the donations page
  And I select "9998 History Fund" from "donation_funds"
  And I select "9997 Misc Fund" from "donation_funds"
  And I press "Search"
  Then I should see the following donations:
  | donor         | amount |
  | Joe Mallon    |    500 |
  | Diana Moore   |    900 |
  | Patrick Tracy |    800 |
  But I should not see the following donations:
  | donor       | amount |
  | Armando Fox |    600 |
  | Tom Foolery |    100 |

Scenario: list all donations

  Given a donation of $10.00 on April 22, 2011 from Tom Foolery
  When I go to the donations page
  And I press "Search"

