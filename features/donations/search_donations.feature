Feature: search donations

  As a development manager
  So that I can find our best donors to help grow the theater
  I want to search our donation history

Background:

  Given I am logged in as staff
  And the following donations:
   | donor         | amount  | fund              |       date |
   | Tom Foolery   | $100.00 | 0000 General Fund | 2012-01-03 |
   | Joe Mallon    | $500.00 | 9998 History Fund | 2012-01-04 |
   | Armando Fox   | $600.00 | 0000 General Fund | 2012-03-05 |
   | Diana Moore   | $900.00 | 9998 History Fund | 2012-07-01 |
   | Patrick Tracy | $800.00 | 9997 Misc Fund    | 2012-08-01 |
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
  And I select "2012-02-02 to 2012-07-01" as the "dates" date range
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

Scenario: from a customer's account page, list their donations

  When I visit the home page for customer "Joe Mallon"
  And I follow "Donations…"
  Then I should see the following donations:
  | donor         | amount |
  | Joe Mallon    |    500 |
  But I should not see the following donations:
  | donor         | amount |
  | Diana Moore   |    900 |
  | Patrick Tracy |    800 |
  | Armando Fox   |    600 |
  | Tom Foolery   |    100 |

@javascript
Scenario: filter donations by donor

  When I check "use_cid"
  And I select customer "Joe Mallon" within "donor_autocomplete"
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
