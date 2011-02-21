Feature: set display order of voucher types

  As a box office manager
  So that I can simplify customers' buying experience
  I want to specify the order in which vouchertypes appear in pulldown menus

Background:

  Given a performance of "Hamlet" on January 21, 2010, 8:00pm
  And   3 General vouchers costing $10 are available for that performance
  And   2 Senior vouchers costing $8 are available for that performance
  And   today is January 20, 2010
 
Scenario: display General vouchers earlier

  Given the display order of the vouchertype with name "General" is set to 3
  And   the display order of the vouchertype with name "Senior" is set to 5
  When  I visit the Store page
  Then  label:"General" should come before label:"Senior" within "div[@id='voucher_menus']"

Scenario: display Senior vouchers earlier

  Given the display order of the vouchertype with name "General" is set to 10
  And   the display order of the vouchertype with name "Senior" is set to 0
  When  I visit the Store page
  Then  label:"General" should come after label:"Senior" within "div[@id='voucher_menus']"

Scenario: display voucher types

  Given I am logged in as box office manager
  And   I set the display order of the vouchertype with name "General" to 10
  And   I set the display order of the vouchertype with name "Senior" to 0
  When  I go to the vouchertypes page for the 2010 season
  Then  a:"Senior" should come before a:"General" within "table[@id='vouchertypes']"
  And   I should see "Sort" within "table[@id='vouchertypes']"
  When  I set the display order of the vouchertype with name "General" to 5
  And   I set the display order of the vouchertype with name "Senior" to 10
  And   I go to the vouchertypes page for the 2010 season
  Then  a:"General" should come before a:"Senior" within "table[@id='vouchertypes']"  

  
