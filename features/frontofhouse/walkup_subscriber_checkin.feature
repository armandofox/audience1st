@javascript
Feature: checkin "walkup" subscriber (without advance reservation)

  As a front of house boxoffice agent
  So that I can give subscribers a quick and pleasant experience at checkin
  I want to checkin subscribers quickly even when they have no reservation

Background: I am logged in as boxoffice and checking in a show

  Given a performance of "Chicago" on April 15, 2010, 8:00pm
  And the "April 15, 2010, 8:00pm" performance has reached its max sales
  And customer "Elaine Henninger" has 1 of 2 open subscriber vouchers for "Chicago"
  And I am logged in as box office
  And I visit the checkin page for April 15, 2010, 8:00pm

Scenario: boxoffice can checkin subscriber who has available vouchers, even if show sold out

  When I select customer "Elaine Henninger" within "walkup_subscriber_search"
  Then I should see "Check which voucher(s) to use"
  When I check "Subscriber - Chicago (Subscriber)"
  And I press "Confirm Check-In"
  Then I should see "1 checkin confirmed for Elaine Henninger."
  And customer "Elaine Henninger" should be checked in for 1 seat on April 15, 2010, 8:00pm 

Scenario: no check-in if boxoffice fails to check any voucher box  

  When  I select customer "Elaine Henninger" within "walkup_subscriber_search"
  And  I press "Confirm Check-In"
  Then I should see "No vouchers were selected for check-in"
  

Scenario: no check-in if subscriber has no available vouchers
