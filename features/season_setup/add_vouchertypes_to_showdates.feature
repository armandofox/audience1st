Feature: add vouchertype(s) to showdate(s)

  As a boxoffice manager
  So that I can make tickets available for shows
  I want to add vouchertypes to existing showdates

Background: logged in as boxoffice managing existing showdates

  Given I am logged in as boxoffice manager
  And a show "Chicago" with the following performances: Mon Feb 15 8pm, Fri Feb 19 8pm, Sat Feb 20 3pm
  And a "General" vouchertype costing $27.00 for the 2010 season
  And a "Student" vouchertype costing $23.00 for the 2010 season
  
Scenario: add vouchertypes for subset of performances

  When I visit the edit ticket redemptions page for "Chicago"
  And I select "Student" from "Voucher/ticket type (Ctrl-click to select multiple)"
  And I fill in "minutes before show time" with "90"
  And I check "Mon 2/15, 8:00"
  And I check "Sat 2/20, 3:00"
  And I press "Apply Changes"
  
