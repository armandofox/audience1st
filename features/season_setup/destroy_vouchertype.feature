Feature: Admin can destroy a voucher type

  As a box office manager
  To retire voucher types we don't want to sell after all
  I want to delete a vouchertype that hasn't sold any

Background:

  Given I am logged in as administrator
  And a "Student" vouchertype costing $13.00 for the 2010 season

@javascript
Scenario: destroy vouchertype if none have been issued

  When I visit the vouchertypes page
  And I click the delete icon for the "Student" vouchertype
  Then a vouchertype with name "Student" should not exist

Scenario: cannot destroy vouchertype if any have been issued


  
