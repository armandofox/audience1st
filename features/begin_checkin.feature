@wip
Feature: begin checkin

  As a box office worker
  So that I can start checking in patrons
  I want to go to the checkin page for this show

  Scenario: visit checkin page
    Given a performance at 8:00pm October 31
    And I am logged in as a box office worker
    And I follow "Box Office"
    And I follow "Reservation Checkin"
    Then I should be on the checkin page 
    And I should see /Oct(ober)?\s+31/i

  Scenario: begin checkin
    Given I am on the checkin page



  
