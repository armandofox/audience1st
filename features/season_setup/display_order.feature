Feature: set display order of voucher types

  As a box office manager
  So that I can simplify customers' buying experience
  I want to specify the order in which vouchertypes appear in pulldown menus

Background:

  Given a performance of "Hamlet" on January 21, 8:00pm
  And   3 General vouchers costing $10 are available for that performance
  And   2 Senior vouchers costing $8 are available for that performance
 
Scenario Outline: display vouchers in correct order

  Given the display orders of "General" and "Senior" are set to <general> and <senior>
  When I visit the Store page
  Then label:"General" should come <when> label:"Senior" within "div[@id='voucher_menus']"

  Examples:
    | general | senior | when   |
    |       3 |      5 | before |
    |      10 |      0 | after  |

Scenario: display voucher types

  Given I am logged in as box office manager
  And   the display orders of "General" and "Senior" are set to 10 and 0
  When  I go to the vouchertypes page for the 2010 season
  Then  a:"Senior" should come before a:"General" within "table[@id='vouchertypes']"
  And   I should see "Sort" within "table[@id='vouchertypes']"
  And   the display orders of "General" and "Senior" are set to 5 and 10
  And   I go to the vouchertypes page for the 2010 season
  Then  a:"General" should come before a:"Senior" within "table[@id='vouchertypes']"  

  
