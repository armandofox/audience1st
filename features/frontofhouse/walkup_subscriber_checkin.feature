@javascript
Feature: checkin walkup subscriber without a reservation

  As a front of house boxoffice agent
  So that I can give subscribers a quick and pleasant experience at checkin
  I want to checkin subscribers quickly even when they have no reservation

Background: logged in as boxoffice and checking in a show

  Given a performance of "Chicago" on April 15, 2010, 8:00pm
  And I am logged in as box office
  And I am on the checkin page for April 15, 2010, 8:00pm

Scenario: check in subscriber who has available vouchers

  Given customer "Elaine Henninger" has 1 of 2 open subscriber vouchers for "Chicago"
  When I visit the walkup subscriber checkin page for April 15, 2010, 8:00pm
  And I select customer "Elaine Henninger" within "walkup_subscriber_search"

Scenario: subscriber has no available vouchers
