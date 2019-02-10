Feature: add vouchertype(s) to showdate(s)

  As a boxoffice manager
  So that I can make tickets available for shows
  I want to add vouchertypes to existing showdates

Background: logged in as boxoffice managing existing showdates

  Given I am logged in as boxoffice manager
  And a show "Chicago" with the following performances: Mon Mar 15 8pm, Fri Mar 19 8pm, Sat Mar 20 3pm
  And a "General" vouchertype costing $27.00 for the 2010 season
  And a "Student" vouchertype costing $23.00 for the 2010 season
  
Scenario: add vouchertypes for subset of performances

  When I visit the edit ticket redemptions page for "Chicago"
  And I check "Student (2010) - $23.00" within "#t-vouchertypes"
  And I fill in "minutes before show time" with "90"
  And I fill in "Max sales for type (Leave blank for unlimited)" with "45"
  And I check "Mon 3/15, 8:00"
  And I check "Sat 3/20, 3:00"
  And I press "Apply Changes"
  Then only the following voucher types should be valid for "Chicago":
    | showdate      | vouchertype | end_sales        | max_sales |
    | Mon 3/15, 8pm | Student     | Mon 3/15, 6:30pm |        45 |
    | Sat 3/20, 3pm | Student     | Sat 3/20, 1:30pm |        45 |
    
Scenario: add vouchertypes in a way that also changes existing ones

  Given the following voucher types are valid for "Chicago":
    | showdate      | vouchertype | end_sales        | max_sales |
    | Mon 3/15, 8pm | Student     | Mon 3/15, 6:30pm |        45 |
    | Sat 3/20, 3pm | Student     | Sat 3/20, 1:30pm |        45 |
