Feature: edit a specific redemption

  As a boxoffice manager
  So that I can change redemption conditions on an individual showdate
  I want to edit a single existing redemption

Background: logged in as boxoffice and redemptions exist for a show  

  Given I am logged in as boxoffice manager
  And a show "Chicago" with the following performances: Mon Mar 15 8pm, Fri Mar 19 8pm
  And a "StudentDiscount" vouchertype costing $27.00 for the 2010 season
  And a "General" vouchertype costing $38.00 for the 2010 season
  And the following voucher types are valid for "Chicago":
    | showdate      | vouchertype     | end_sales        | max_sales | promo_code |
    | Mon 3/15, 8pm | StudentDiscount | Mon 3/15, 6:30pm |        45 | STU        |
    | Mon 3/15, 8pm | General         | Mon 3/15, 6:00pm |        35 |            |

Scenario: change properties on a single redemption

  When I visit the show details page for "Chicago"
  And I follow "StudentDiscount"
  Then I should see "Edit Ticket Redemption"
  And I should see "Chicago - Monday, Mar 15, 8:00 PM"
  And I should see "StudentDiscount"
  And the "Redemption (promo) code, if any" field should equal "STU"
  And the "Max sales for type (Leave blank for unlimited)" field should equal "45"
  And "Mon, 3/15, 6:30pm" should be selected as the "End sales" date
  When I fill in "Max sales for type (Leave blank for unlimited)" with "25"
  And I fill in "Redemption (promo) code, if any" with "ZOOX"
  And I press "Save Changes"
  Then only the following voucher types should be valid for "Chicago":
    | showdate      | vouchertype     | end_sales        | max_sales | promo_code |
    | Mon 3/15, 8pm | StudentDiscount | Mon 3/15, 6:30pm |        25 | ZOOX       |
    | Mon 3/15, 8pm | General         | Mon 3/15, 6:00pm |        35 |            |

