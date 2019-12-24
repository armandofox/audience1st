Feature: generate advance sales reports

  As the bookkeeper
  So that I can get accurate info for royalty applications and grants
  I want to generate advance sales reports for arbitrary sets of shows

Background:

  Given I am logged in as box office manager
  And   the following shows exist:
  | name      | opening_date | closing_date | house_capacity |
  | Hamlet    |   2010-01-01 |   2010-01-31 |             50 |
  | King Lear |   2012-01-20 |   2012-01-31 |             50 |
  And   a performance of "Hamlet" on "January 21, 2010, 8:00pm"
  And   a performance of "King Lear" on "January 23, 2012, 8:00pm"
  And   a performance of "King Lear" on "January 24, 2012, 8:00pm"
  And   I am on the reports page

Scenario: generate sales report for two shows


  When  I select "Hamlet (Dec 2009 - Feb 2010)" from "shows"
  And   I select "King Lear (Dec 2011 - Feb 2012)" from "shows"
  And   I press "advance_sales"
  Then  I should see "1 performance" within the div for the show with name "Hamlet"
  And   I should see "2 performances" within the div for the show with name "King Lear"



Scenario: download advance_sales cvs for one show

  Given a "General" vouchertype costing $37.00 for the 2012 season
  And a "Student" vouchertype costing $31.00 for the 2012 season
  And the following voucher types are valid for "King Lear":
    | showdate                 | vouchertype | end_sales                 | max_sales |
    | January 23, 2012, 8:00pm | General     | January 30, 2012, 10:00pm |        50 |
    | January 23, 2012, 8:00pm | Student     | January 30, 2012, 10:00pm |        50 |
  And the following orders have been placed:
    |       date | customer      | item1        | item2        | payment     |
    | 2012-01-20 | Tom Foolery   | 2x General   |              | credit card |
    | 2010-01-20 | Armando Fox   | 1x Student   |              | credit card |
  And   I select "King Lear (Dec 2011 - Feb 2012)" from "shows"
  When  I press "Download to Excel" within "#advance_sales_report"
  Then  a CSV file should be downloaded containing:
    | Show Name | Run Dates               | Show Date                | House Capacity | Max Advance Sales for Performance | Voucher Type | Subscriber Voucher? | Max Sales for voucher type | Number Sold | Price | Gross Receipts |
    | King Lear | 2012-01-20 - 2012-01-31 | January 23, 2012, 8:00pm | 50             | 50                                | General      | NO                  | 50                         | 2           | 37.00 | 74.00          |
    | King Lear | 2012-01-20 - 2012-01-31 | January 23, 2012, 8:00pm | 50             | 50                                | Student      | NO                  | 50                         | 1           | 31.00 | 31.00          |
