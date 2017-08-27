Feature: edit bundle vouchertype

  As a box office manager
  In order to play around with different bundles
  I want to edit the vouchertypes included in a bundle

Background: existing bundle

  Given a bundle "Sub" for $50.00 containing:
    | show      | date              | qty |
    | Hamlet    | May 12, 2010, 8pm |   3 |
    | King Lear | May 13, 2010, 8pm |   4 |
  And I am logged in as box office manager

Scenario: change contents of bundle

  When I visit the edit page for the "Sub" vouchertype
  And I fill in the "Included vouchers:" fields as follows:
    | field              | value |
    | Hamlet (bundle)    |     2 |
    | King Lear (bundle) |     0 |
  And I press "Save Changes"
  Then the "Sub" bundle should include:
    | name            | quantity |
    | Hamlet (bundle) |        2 |
  But the "Sub" bundle should not include:
    | name               |
    | King Lear (bundle) |

Scenario: cannot leave a bundle empty
