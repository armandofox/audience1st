Feature: customer can make a reservation against an open voucher

  As a customer
  For courteous and efficient self-service
  I want to use an open voucher to make a reservation for a show

Background: logged in customer has an open voucher

  Given I am logged in as customer "Tom Foolery"
  And I have 1 "General" open voucher reservable for the following showdates:
  | show    | date                 | advance_sales_cutoff | seats_remaining |
  | Hamlet  | Dec 11, 2013, 8:00pm | Dec 11, 2013, 6:00pm |               5 |
  | Macbeth | Dec 18, 2013, 8:00pm | Dec 18, 2013, 6:00pm |               3 |

Scenario: make reservation for available show

  When I go to the make-reservations page for that voucher

Scenario: cannot make reservation if show is sold out

Scenario: cannot make reservation if show's advance reservations are closed

Scenario: cannot make reservation for invalid show
