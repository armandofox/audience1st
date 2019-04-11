Feature: add vouchertype(s) to showdate(s)

  As a boxoffice manager
  So that I can make tickets available for shows
  I want to add vouchertypes to existing showdates

Background: logged in as boxoffice managing existing showdates

  Given I am logged in as boxoffice manager
  And a show "Chicago" with the following performances: Mon Mar 15 8pm, Fri Mar 19 8pm, Sat Mar 20 3pm, Sat Mar 20 8pm
  And a "General" vouchertype costing $27.00 for the 2010 season
  And a "Student" vouchertype costing $23.00 for the 2010 season
  
Scenario: add vouchertypes for subset of performances

  When I visit the edit ticket redemptions page for "Chicago"
  And I select the following vouchertypes: Student
  And I select "March 1, 2010, 12:00am" as the "Start sales for each performance" time
  And I set end sales to "90" minutes before show time
  And I fill in "Max sales for type (leave blank for unlimited)" with "45"
  And I select the following show dates: 3/15 8:00pm, 3/20 3:00pm
  And I press "Apply Changes"
  Then only the following voucher types should be valid for "Chicago":
    | showdate      | vouchertype | end_sales        | max_sales |
    | Mon 3/15, 8pm | Student     | Mon 3/15, 6:30pm |        45 |
    | Sat 3/20, 3pm | Student     | Sat 3/20, 1:30pm |        45 |
    
Scenario: add vouchertypes in a way that also changes existing ones

  Given the following voucher types are valid for "Chicago":
    | showdate      | vouchertype | end_sales        | max_sales |
    | Mon 3/15, 8pm | Student     | Mon 3/15, 6:30pm |        45 |
    | Mon 3/15, 8pm | General     | Mon 3/15, 6:00pm |        35 |
    | Fri 3/19, 8pm | Student     | Fri 3/19, 6:00pm |        20 |
    | Sat 3/20, 3pm | Student     | Sat 3/20, 1:30pm |        45 |
  When I visit the edit ticket redemptions page for "Chicago"
  And I select the following vouchertypes: Student, General
  And I select the following show dates: 3/15 8:00pm, 3/20 8:00pm
  And I set end sales to "20" minutes before show time
  And I fill in "Max sales for type (leave blank for unlimited)" with "50"
  And I choose to overwrite existing redemptions
  And I press "Apply Changes"
  Then only the following voucher types should be valid for "Chicago":
    | showdate      | vouchertype | end_sales        | max_sales |
    | Mon 3/15, 8pm | Student     | Mon 3/15, 7:40pm |        50 |
    | Mon 3/15, 8pm | General     | Mon 3/15, 7:40pm |        50 |
    | Sat 3/20, 8pm | Student     | Sat 3/20, 7:40pm |        50 |
    | Sat 3/20, 8pm | General     | Sat 3/20, 7:40pm |        50 |
    | Fri 3/19, 8pm | Student     | Fri 3/19, 6:00pm |        20 |
    | Sat 3/20, 3pm | Student     | Sat 3/20, 1:30pm |        45 |
    
Scenario: leave end sales unchanged while updating max sales

  Given the following voucher types are valid for "Chicago":
    | showdate      | vouchertype | end_sales        | max_sales |
    | Mon 3/15, 8pm | Student     | Mon 3/15, 6:30pm |        45 |
    | Mon 3/15, 8pm | General     | Mon 3/15, 6:00pm |        35 |
    | Fri 3/19, 8pm | Student     | Fri 3/19, 6:00pm |        20 |
    | Sat 3/20, 3pm | Student     | Sat 3/20, 1:30pm |        45 |
  When I visit the edit ticket redemptions page for "Chicago"
  And I select the following vouchertypes: Student
  And I select the following show dates: 3/15 8:00pm, 3/20 3:00pm
  And I choose to leave as-is on existing redemptions: end sales
  And I fill in "Max sales for type (leave blank for unlimited)" with "21"
  And I press "Apply Changes"
  Then only the following voucher types should be valid for "Chicago":
    | showdate      | vouchertype | end_sales        | max_sales |
    | Mon 3/15, 8pm | Student     | Mon 3/15, 6:30pm |        21 |
    | Mon 3/15, 8pm | General     | Mon 3/15, 6:00pm |        35 |
    | Fri 3/19, 8pm | Student     | Fri 3/19, 6:00pm |        20 |
    | Sat 3/20, 3pm | Student     | Sat 3/20, 1:30pm |        21 |

Scenario: can't leave vouchertypes blank

  When I visit the edit ticket redemptions page for "Chicago"
  And I choose to leave as-is on existing redemptions: end sales
  And I select the following show dates: 3/15 8:00pm, 3/20 3:00pm
  And I press "Apply Changes"
  Then I should see "You must select 1 or more voucher types to add."
  And I should see "Add ticket type(s) for Chicago"

