Feature: search donations

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
  And I visit the donations page

Scenario: filter donations by fund
  
  When I select "9998 History Fund" from "donation_funds"
  And I select "9997 Misc Fund" from "donation_funds"
  And I check "use_fund"
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

Scenario: filter donations by date

  When I check "use_date"
  And I select "2/1/2012 to 7/1/2012" as the "dates" date range
  And I press "Search"
  Then I should see the following donations:
  | donor       | amount |
  | Armando Fox |    600 |
  | Diana Moore |    900 |
  But I should not see the following donations:
  | donor         | amount |
  | Joe Mallon    |    500 |
  | Tom Foolery   |    100 |
  | Patrick Tracy |    800 |

Scenario: list all donations

  When I press "Search"
  Then I should see the following donations:
  | donor         | amount |
  | Joe Mallon    |    500 |
  | Diana Moore   |    900 |
  | Patrick Tracy |    800 |
  | Armando Fox   |    600 |
  | Tom Foolery   |    100 |

Scenario: filter donations by donor

  When I check "use_cid"
  And I fill in the customer autocomplete with "Joe Mallon"
  And I press "Search"
  Then I should see the following donations:
  | donor         | amount |
  | Joe Mallon    |    500 |
  But I should not see the following donations:
  | donor         | amount |
  | Diana Moore   |    900 |
  | Patrick Tracy |    800 |
  | Armando Fox   |    600 |
  | Tom Foolery   |    100 |
