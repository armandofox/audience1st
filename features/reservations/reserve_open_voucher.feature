@time
Feature: customer can make a reservation against an open voucher

  As a customer
  For courteous and efficient self-service
  I want to use an open voucher to make a reservation for a show

Background: logged in customer has an open voucher

  Given today is Dec 1, 2010
  And I am logged in as customer "Tom Foolery"
  And a show "Macbeth" with 2 "General" tickets for $10 on "Dec 5, 2010, 8pm"

Scenario: make reservation for available show

  Given I have 1 "General" open voucher
  When I reserve that voucher for 

Scenario: cannot make reservation if show is sold out

Scenario: cannot make reservation if show's advance reservations are closed

Scenario: cannot make reservation for invalid show
